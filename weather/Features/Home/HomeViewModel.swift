//
//  HomeViewModel.swift
//  weather
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum WeatherState {
        case idle
        case loading
        case loaded(WeatherPayload)
        case failed(String)
    }

    @Published private(set) var places: [Place] = []
    @Published var selectedPlaceId: String?
    @Published private(set) var weatherByPlaceId: [String: WeatherState] = [:]
    @Published private(set) var refreshingPlaceIds: Set<String> = []

    private let weatherProvider: any WeatherProviding
    private let cityStore: any CityListStoring
    private let weatherCacheStore: any WeatherCacheStoring
    private var tasks: [String: Task<Void, Never>] = [:]
    private var loadTask: Task<Void, Never>?

    init(
        weatherProvider: any WeatherProviding,
        cityStore: any CityListStoring,
        weatherCacheStore: any WeatherCacheStoring
    ) {
        self.weatherProvider = weatherProvider
        self.cityStore = cityStore
        self.weatherCacheStore = weatherCacheStore

        loadTask = Task { [weak self] in
            await self?.loadFromDisk()
        }
    }

    func loadFromDisk() async {
        let savedPlaces = await cityStore.loadPlaces()
        let savedSelectedId = await cityStore.loadSelectedPlaceId()
        let cached = await weatherCacheStore.loadCache()

        places = savedPlaces
        selectedPlaceId = savedSelectedId ?? savedPlaces.first?.id

        // Keep selected city consistent.
        if let selectedPlaceId, !places.contains(where: { $0.id == selectedPlaceId }) {
            self.selectedPlaceId = places.first?.id
        }

        // Prime weather state map from cache so we can render immediately.
        for place in places {
            if let payload = cached[place.id] {
                weatherByPlaceId[place.id] = .loaded(payload)
            } else if weatherByPlaceId[place.id] == nil {
                weatherByPlaceId[place.id] = .idle
            }
        }

        refreshAllPlaces()
    }

    func selectPlaceId(_ placeId: String) {
        selectedPlaceId = placeId
        Task { [cityStore] in
            await cityStore.saveSelectedPlaceId(placeId)
        }

        // Always refresh when switching cities (hot update behavior).
        fetchWeather(for: placeId)
    }

    func addPlace(_ place: Place) {
        let trimmedName = place.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        var next = places.filter { $0.id != place.id }
        if place.id == "current-location" {
            next.insert(place, at: 0)
        } else {
            next.append(place)
        }
        places = next

        if weatherByPlaceId[place.id] == nil {
            weatherByPlaceId[place.id] = .idle
        }

        selectedPlaceId = place.id
        Task { [cityStore, next, placeId = place.id] in
            await cityStore.savePlaces(next)
            await cityStore.saveSelectedPlaceId(placeId)
        }
        fetchWeather(for: place.id)
    }

    func removePlaceId(_ placeId: String) {
        guard !placeId.isEmpty else { return }
        guard places.contains(where: { $0.id == placeId }) else { return }

        tasks[placeId]?.cancel()
        tasks[placeId] = nil
        refreshingPlaceIds.remove(placeId)
        weatherByPlaceId.removeValue(forKey: placeId)

        let next = places.filter { $0.id != placeId }
        places = next

        if selectedPlaceId == placeId {
            selectedPlaceId = next.first?.id
        }

        Task { [cityStore, weatherCacheStore, next, selectedPlaceId] in
            await cityStore.savePlaces(next)
            await cityStore.saveSelectedPlaceId(selectedPlaceId)
            await weatherCacheStore.remove(placeId: placeId)
        }
    }

    func refreshAllPlaces() {
        for place in places {
            fetchWeather(for: place.id)
        }
    }

    func fetchWeather(for placeId: String) {
        tasks[placeId]?.cancel()
        let previous = weatherByPlaceId[placeId]
        refreshingPlaceIds.insert(placeId)
        if previous == nil {
            weatherByPlaceId[placeId] = .idle
        }

        tasks[placeId] = Task { [weak self] in
            do {
                guard let place = self?.places.first(where: { $0.id == placeId }) else { return }
                let payload = try await self?.weatherProvider.weather(for: place)
                guard let payload else { return }
                if Task.isCancelled { return }
                self?.refreshingPlaceIds.remove(placeId)
                self?.weatherByPlaceId[placeId] = .loaded(payload)
                Task { [weatherCacheStore = self?.weatherCacheStore] in
                    await weatherCacheStore?.save(placeId: placeId, payload: payload)
                }
            } catch {
                if Task.isCancelled { return }
                self?.refreshingPlaceIds.remove(placeId)

                // If we were refreshing an already-loaded city, keep the previous data to avoid UI flashing.
                switch previous {
                case .loaded:
                    break
                default:
                    self?.weatherByPlaceId[placeId] = .failed(error.localizedDescription)
                }
            }
        }
    }

    func refreshSelectedPlace() {
        guard let selectedPlaceId else { return }
        fetchWeather(for: selectedPlaceId)
    }
}
