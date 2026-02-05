//
//  CitySuggesting.swift
//  weather
//
//  Provides city/province suggestions for the Weather feature.
//

import Foundation

protocol CitySuggesting: Sendable {
    func suggestions(matching query: String, limit: Int) async throws -> [Place]
}
