//
//  CityListStoring.swift
//  weather
//
//  Stores user's "added cities" list (not search suggestions).
//

import Foundation

protocol CityListStoring: Sendable {
    func loadCities() async -> [String]
    func saveCities(_ cities: [String]) async

    func loadSelectedCity() async -> String?
    func saveSelectedCity(_ city: String?) async
}

