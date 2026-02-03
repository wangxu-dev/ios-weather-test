//
//  LocationNormalizing.swift
//  weather
//

import Foundation

protocol LocationNormalizing: Sendable {
    func cityCandidates(from ipLocation: IPLocation) -> [String]
    func rawLocationText(from ipLocation: IPLocation) -> String

    func cityCandidates(from locationText: String) -> [String]
    func rawLocationText(from locationText: String) -> String
}

/// A simple normalizer tuned for common CN address formats.
struct DefaultLocationNormalizer: LocationNormalizing {
    func rawLocationText(from ipLocation: IPLocation) -> String {
        [
            ipLocation.country,
            ipLocation.region,
            ipLocation.city,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    func cityCandidates(from ipLocation: IPLocation) -> [String] {
        var out: [String] = []

        if let city = ipLocation.city {
            out.append(normalizeCNPlaceName(city))
        }
        if let region = ipLocation.region {
            out.append(normalizeCNPlaceName(region))
        }

        // Remove empties and duplicates while preserving order.
        var seen: Set<String> = []
        return out
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    func rawLocationText(from locationText: String) -> String {
        locationText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cityCandidates(from locationText: String) -> [String] {
        let trimmed = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Example: "新疆维吾尔自治区昌吉回族自治州昌吉市 电信"
        // We want the most specific city-level name if possible.
        //
        // NOTE: The location string often contains only CJK characters, so we cannot just
        // "take the last run of CJK" before a suffix; we'd end up grabbing the whole prefix.
        // Instead, we extract the token after the last administrative boundary before a suffix.

        // Drop ISP/carrier tail (usually after a space).
        let core = trimmed.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? trimmed

        var candidates: [String] = []

        if let city = extractName(afterLastBoundaryBefore: "市", in: core) {
            candidates.append(city)         // e.g. 昌吉
            candidates.append(city + "市")  // e.g. 昌吉市
        }
        if let prefecture = extractName(afterLastBoundaryBefore: "自治州", in: core) {
            candidates.append(prefecture)              // e.g. 昌吉
            candidates.append(prefecture + "自治州")   // e.g. 昌吉自治州
        }
        if let region = extractName(afterLastBoundaryBefore: "地区", in: core) {
            candidates.append(region)
            candidates.append(region + "地区")
        }
        if let state = extractName(afterLastBoundaryBefore: "州", in: core) {
            candidates.append(state)
            candidates.append(state + "州")
        }
        if let league = extractName(afterLastBoundaryBefore: "盟", in: core) {
            candidates.append(league)
            candidates.append(league + "盟")
        }

        // Dedupe and normalize suffixes.
        var seen: Set<String> = []
        return candidates
            .map { normalizeCNPlaceName($0) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    private func normalizeCNPlaceName(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Common suffixes.
        let suffixes = [
            // Prefer longer composite suffixes first.
            "维吾尔自治区", "回族自治区", "壮族自治区", "蒙古自治区", "藏族自治区",
            "市", "省", "区", "县", "州", "盟", "地区", "特别行政区", "自治区",
        ]
        for s in suffixes {
            if t.hasSuffix(s) {
                t.removeLast(s.count)
                break
            }
        }
        // Direct-controlled municipalities sometimes already match, but keep it safe.
        return t
    }

    private func extractName(afterLastBoundaryBefore suffix: String, in text: String) -> String? {
        guard let suffixRange = text.range(of: suffix, options: [.backwards]) else { return nil }
        let beforeSuffix = text[..<suffixRange.lowerBound]

        // Find the last administrative boundary before the suffix.
        // We prefer longer boundaries first to avoid partial matches (e.g. "自治区" contains "区").
        let boundaries = [
            "特别行政区",
            "维吾尔自治区", "回族自治区", "壮族自治区", "蒙古自治区", "藏族自治区",
            "自治区",
            "省",
            "地区",
            "自治州",
            "州",
            "盟",
            "市",
        ]

        var cutIndex = beforeSuffix.startIndex
        for b in boundaries {
            if let r = beforeSuffix.range(of: b, options: [.backwards]) {
                if r.upperBound > cutIndex {
                    cutIndex = r.upperBound
                }
            }
        }

        let token = beforeSuffix[cutIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : String(token)
    }
}
