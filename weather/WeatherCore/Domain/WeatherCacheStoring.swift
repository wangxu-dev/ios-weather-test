//
//  WeatherCacheStoring.swift
//  weather
//
//  Persist last-known weather data so the UI can render immediately on launch,
//  then refresh in the background (silent hot update).
//

import Foundation

protocol WeatherCacheStoring: Sendable {
    func loadCache() async -> [String: WeatherPayload]
    func save(city: String, payload: WeatherPayload) async
    func remove(city: String) async
    func clear() async
}

