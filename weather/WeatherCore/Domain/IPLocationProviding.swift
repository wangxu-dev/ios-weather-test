//
//  IPLocationProviding.swift
//  weather
//

import Foundation

/// Raw IP-based location response (provider-specific fields are kept optional).
///
/// This model matches ipinfo.io `/json` by default:
/// `{ ip, city, region, country, loc, org, postal, timezone, ... }`.
struct IPLocation: Codable, Hashable, Sendable {
    var ip: String
    var city: String?
    var region: String?
    var country: String?
    var loc: String?
    var org: String?
    var postal: String?
    var timezone: String?

    // ipinfo includes this field when unauthenticated; keep it for diagnostics.
    var readme: String?
}

protocol IPLocationProviding: Sendable {
    func fetchIPLocation() async throws -> IPLocation
}

