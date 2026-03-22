import Foundation

nonisolated actor UserDefaultsWeatherCacheStore: WeatherCachePersistence {
    private let defaults: UserDefaults
    private let cacheKey = "weather.cache.v3"
    private let migratedKey = "migration.weather.cache.v3.done"

    private let legacyCacheKey = "weatherCache.v2"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async -> [PlaceID: WeatherSnapshot] {
        await migrateIfNeeded()
        guard let data = defaults.data(forKey: cacheKey) else { return [:] }
        let decoded = (try? JSONDecoder().decode([String: WeatherSnapshot].self, from: data)) ?? [:]
        return Dictionary(uniqueKeysWithValues: decoded.map { (PlaceID(rawValue: $0.key), $0.value) })
    }

    func save(snapshot: WeatherSnapshot, for id: PlaceID) async {
        var next = await load()
        next[id] = snapshot
        let encoded = Dictionary(uniqueKeysWithValues: next.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    func remove(for id: PlaceID) async {
        var next = await load()
        next.removeValue(forKey: id)
        let encoded = Dictionary(uniqueKeysWithValues: next.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    private func migrateIfNeeded() async {
        guard !defaults.bool(forKey: migratedKey) else { return }
        defer { defaults.set(true, forKey: migratedKey) }

        guard let data = defaults.data(forKey: legacyCacheKey) else { return }
        guard let old = try? JSONDecoder().decode(LegacyWeatherCacheSnapshot.self, from: data) else { return }

        var next: [String: WeatherSnapshot] = [:]
        for (key, payload) in old.byPlaceId {
            guard let domain = payload.toWeatherSnapshot(placeID: PlaceID(rawValue: key)) else { continue }
            next[key] = domain
        }

        guard let encoded = try? JSONEncoder().encode(next) else { return }
        defaults.set(encoded, forKey: cacheKey)
    }
}

nonisolated private struct LegacyWeatherCacheSnapshot: Codable, Sendable {
    var byPlaceId: [String: LegacyWeatherPayload]
}

nonisolated private struct LegacyWeatherPayload: Codable, Sendable {
    nonisolated struct Info: Codable, Sendable {
        var city: String
        var updateTime: String
        var tempCurrent: String?
        var tempHigh: String
        var tempLow: String
        var weatherCode: Int?
        var isDay: Bool?
    }

    var weatherInfo: Info?

    func toWeatherSnapshot(placeID: PlaceID) -> WeatherSnapshot? {
        guard let weatherInfo else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = formatter.date(from: weatherInfo.updateTime) ?? Date()

        let place = Place(
            id: placeID,
            name: weatherInfo.city,
            coordinate: Coordinate(latitude: 0, longitude: 0)
        )

        let condition = WeatherConditionCode(rawValue: weatherInfo.weatherCode ?? 0) ?? .clearSky
        let current = CurrentWeather(
            observationTime: now,
            condition: condition,
            isDay: weatherInfo.isDay ?? true,
            temperature: Measurement(value: Double(weatherInfo.tempCurrent ?? weatherInfo.tempHigh) ?? 0, unit: .celsius),
            apparentTemperature: nil,
            humidity: nil,
            windSpeed: Measurement(value: 0, unit: .metersPerSecond),
            windDirectionDegrees: 0,
            windGust: nil,
            pressure: nil,
            visibility: nil,
            precipitation: nil
        )

        return WeatherSnapshot(
            place: place,
            timezoneIdentifier: TimeZone.current.identifier,
            fetchedAt: now,
            validUntil: now.addingTimeInterval(300),
            current: current,
            hourly: [],
            daily: []
        )
    }
}
