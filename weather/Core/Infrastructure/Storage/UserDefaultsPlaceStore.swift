import Foundation

nonisolated actor UserDefaultsPlaceStore: PlacePersistence {
    private let defaults: UserDefaults
    private let placesKey = "places.v3"
    private let selectedKey = "selected.place.id.v3"
    private let migratedKey = "migration.places.v3.done"

    private let legacyPlacesKey = "addedPlaces.v1"
    private let legacySelectedKey = "selectedPlaceId.v1"
    private let legacySelectedNameKey = "selectedCity.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPlaces() async -> [Place] {
        await runMigrationIfNeeded()
        guard let data = defaults.data(forKey: placesKey) else { return [] }
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    func savePlaces(_ places: [Place]) async {
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: placesKey)
    }

    func loadSelectedPlaceID() async -> PlaceID? {
        await runMigrationIfNeeded()
        guard let value = defaults.string(forKey: selectedKey) else { return nil }
        return PlaceID(rawValue: value)
    }

    func saveSelectedPlaceID(_ id: PlaceID?) async {
        if let id {
            defaults.set(id.rawValue, forKey: selectedKey)
        } else {
            defaults.removeObject(forKey: selectedKey)
        }
    }

    private func runMigrationIfNeeded() async {
        guard !defaults.bool(forKey: migratedKey) else { return }

        var migratedPlaces: [Place] = []
        if let data = defaults.data(forKey: legacyPlacesKey), let decoded = try? JSONDecoder().decode([LegacyPlace].self, from: data) {
            migratedPlaces = decoded.compactMap { $0.toDomain() }
        }
        if !migratedPlaces.isEmpty, let encoded = try? JSONEncoder().encode(migratedPlaces) {
            defaults.set(encoded, forKey: placesKey)
        }

        if let selected = defaults.string(forKey: legacySelectedKey) {
            defaults.set(selected, forKey: selectedKey)
        } else if let selectedName = defaults.string(forKey: legacySelectedNameKey) {
            if let mapped = migratedPlaces.first(where: { $0.name == selectedName }) {
                defaults.set(mapped.id.rawValue, forKey: selectedKey)
            }
        }

        defaults.set(true, forKey: migratedKey)
    }
}

nonisolated private struct LegacyPlace: Codable, Sendable {
    var id: String
    var name: String
    var country: String?
    var admin1: String?
    var latitude: Double?
    var longitude: Double?

    func toDomain() -> Place? {
        guard let latitude, let longitude else { return nil }
        return Place(
            id: PlaceID(rawValue: id),
            name: name,
            admin: admin1,
            country: country,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            isCurrentLocation: id == "current-location"
        )
    }
}
