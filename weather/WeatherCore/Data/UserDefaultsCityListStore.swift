//
//  UserDefaultsCityListStore.swift
//  weather
//

import Foundation

final class UserDefaultsCityListStore: CityListStoring {
    static let shared = UserDefaultsCityListStore()

    private let placesKey = "addedPlaces.v1"
    private let selectedKey = "selectedPlaceId.v1"
    private let legacyCitiesKey = "addedCities.v1"
    private let legacySelectedKey = "selectedCity.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPlaces() async -> [Place] {
        if let data = defaults.data(forKey: placesKey) {
            if let decoded = try? JSONDecoder().decode([Place].self, from: data) {
                return decoded
            }
        }

        // Migration from legacy string-based list.
        let legacy = (defaults.array(forKey: legacyCitiesKey) as? [String]) ?? []
        if legacy.isEmpty { return [] }
        return legacy.map { Place(name: $0) }
    }

    func savePlaces(_ places: [Place]) async {
        if let data = try? JSONEncoder().encode(places) {
            defaults.set(data, forKey: placesKey)
        }
    }

    func loadSelectedPlaceId() async -> String? {
        if let placeId = defaults.string(forKey: selectedKey) {
            return placeId
        }

        // Migration from legacy selected city name.
        if let city = defaults.string(forKey: legacySelectedKey) {
            return Place(name: city).id
        }

        return nil
    }

    func saveSelectedPlaceId(_ placeId: String?) async {
        if let placeId {
            defaults.set(placeId, forKey: selectedKey)
        } else {
            defaults.removeObject(forKey: selectedKey)
        }
    }
}
