//
//  CityAutoMatching.swift
//  weather
//

import Foundation

/// The result of auto-matching a located city to a supported weather city list.
struct CityAutoMatchResult: Hashable, Sendable {
    var rawLocationText: String
    var locatedCandidates: [String]
    /// If we can confidently map to exactly one supported city, it will be here.
    var matchedCity: String?
    /// Otherwise, provide suggestions the UI can show for user selection.
    var suggestedCities: [String]
}

protocol CityAutoMatching: Sendable {
    func resolveCity() async throws -> CityAutoMatchResult
}

/// Default resolver: locate city candidates, then ask `CitySuggesting` to map to supported cities.
final class DefaultCityAutoMatcher: CityAutoMatching {
    private let locator: any CityLocating
    private let suggester: any CitySuggesting

    init(locator: any CityLocating, suggester: any CitySuggesting) {
        self.locator = locator
        self.suggester = suggester
    }

    func resolveCity() async throws -> CityAutoMatchResult {
        let located = try await locator.locateCityCandidates()

        // Collect supported-city suggestions for each candidate.
        var combined: [String] = []
        for candidate in located.cityCandidates {
            let list = try await suggester.suggestions(matching: candidate, limit: 10)
            combined.append(contentsOf: list)
        }

        // Dedupe while preserving order.
        var seen: Set<String> = []
        let deduped = combined.filter { seen.insert($0).inserted }

        // If we got exactly one supported city, accept it.
        let matched = deduped.count == 1 ? deduped.first : nil
        #if DEBUG
        print("[CityAutoMatcher] raw=\(located.rawLocationText) candidates=\(located.cityCandidates) deduped=\(deduped) matched=\(matched ?? "nil")")
        #endif

        return CityAutoMatchResult(
            rawLocationText: located.rawLocationText,
            locatedCandidates: located.cityCandidates,
            matchedCity: matched,
            suggestedCities: matched == nil ? deduped : []
        )
    }
}
