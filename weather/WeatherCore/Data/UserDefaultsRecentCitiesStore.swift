//
//  UserDefaultsRecentCitiesStore.swift
//  weather
//

import Foundation

final class UserDefaultsRecentCitiesStore: RecentCitiesStoring {
    static let shared = UserDefaultsRecentCitiesStore()

    private let key = "recentCities.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async -> [String] {
        (defaults.array(forKey: key) as? [String]) ?? []
    }

    func save(_ cities: [String]) async {
        defaults.set(cities, forKey: key)
    }
}

