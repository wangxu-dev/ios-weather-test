//
//  RecentCitiesStoring.swift
//  weather
//
//  Stores user recent cities for quick access.
//

import Foundation

protocol RecentCitiesStoring: Sendable {
    func load() async -> [String]
    func save(_ cities: [String]) async
}

