//
//  UserDefaultsWeatherCacheStore.swift
//  weather
//

import Foundation

final class UserDefaultsWeatherCacheStore: WeatherCacheStoring {
    static let shared = UserDefaultsWeatherCacheStore()

    private struct Snapshot: Codable {
        var byPlaceId: [String: WeatherPayload]
        var savedAt: Date
    }

    private let key = "weatherCache.v2"
    private let legacyKey = "weatherCache.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCache() async -> [String: WeatherPayload] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        do {
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            return snapshot.byPlaceId
        } catch {
            return [:]
        }
    }

    func save(placeId: String, payload: WeatherPayload) async {
        let trimmed = placeId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var next = await loadCache()
        next[trimmed] = payload
        let snapshot = Snapshot(byPlaceId: next, savedAt: Date())
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: key)
        } catch {
            // Cache failures should not affect UI flow.
        }
    }

    func remove(placeId: String) async {
        let trimmed = placeId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var next = await loadCache()
        next.removeValue(forKey: trimmed)
        let snapshot = Snapshot(byPlaceId: next, savedAt: Date())
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: key)
        } catch {
            // Ignore.
        }
    }

    func clear() async {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }
}
