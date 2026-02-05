//
//  CityListStoring.swift
//  weather
//
//  Stores user's "added cities" list (not search suggestions).
//

import Foundation

protocol CityListStoring: Sendable {
    func loadPlaces() async -> [Place]
    func savePlaces(_ places: [Place]) async

    func loadSelectedPlaceId() async -> String?
    func saveSelectedPlaceId(_ placeId: String?) async
}
