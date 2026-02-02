//
//  WeatherComCnCityListCache.swift
//  weather
//

import Foundation

struct WeatherComCnCityInfo: Decodable, Sendable {
    let n: String
    let x: String
    let y: String
}

protocol CityListCaching: Sendable {
    func getCachedCityList() async -> [String: WeatherComCnCityInfo]?
    func setCachedCityList(_ cities: [String: WeatherComCnCityInfo]) async
}

actor InMemoryCityListCache: CityListCaching {
    static let shared = InMemoryCityListCache()

    // City list changes infrequently, cache for 24 hours.
    private let ttl: TimeInterval = 24 * 60 * 60
    private var cachedAt: Date?
    private var cities: [String: WeatherComCnCityInfo]?

    func getCachedCityList() async -> [String: WeatherComCnCityInfo]? {
        guard let cachedAt, let cities else { return nil }
        if Date().timeIntervalSince(cachedAt) > ttl {
            self.cachedAt = nil
            self.cities = nil
            return nil
        }
        return cities
    }

    func setCachedCityList(_ cities: [String: WeatherComCnCityInfo]) async {
        self.cities = cities
        self.cachedAt = Date()
    }
}

