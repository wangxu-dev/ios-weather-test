//
//  CityLocating.swift
//  weather
//

import Foundation

/// Normalized city-locating result, independent from the underlying provider.
struct CityLocationResult: Hashable, Sendable {
    /// Human-readable raw location (for debugging or UI).
    var rawLocationText: String
    /// Candidate city names that the app can try to match to the weather data source.
    var cityCandidates: [String]
}

protocol CityLocating: Sendable {
    func locateCityCandidates() async throws -> CityLocationResult
}

