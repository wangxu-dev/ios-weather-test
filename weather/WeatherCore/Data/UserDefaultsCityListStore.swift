//
//  UserDefaultsCityListStore.swift
//  weather
//

import Foundation

final class UserDefaultsCityListStore: CityListStoring {
    static let shared = UserDefaultsCityListStore()

    private let citiesKey = "addedCities.v1"
    private let selectedKey = "selectedCity.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCities() async -> [String] {
        (defaults.array(forKey: citiesKey) as? [String]) ?? []
    }

    func saveCities(_ cities: [String]) async {
        defaults.set(cities, forKey: citiesKey)
    }

    func loadSelectedCity() async -> String? {
        defaults.string(forKey: selectedKey)
    }

    func saveSelectedCity(_ city: String?) async {
        if let city {
            defaults.set(city, forKey: selectedKey)
        } else {
            defaults.removeObject(forKey: selectedKey)
        }
    }
}

