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

    @Published private(set) var cities: [String] = []
    @Published var selectedCity: String?
    @Published private(set) var weatherByCity: [String: WeatherState] = [:]
    @Published private(set) var refreshingCities: Set<String> = []

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
        let savedCities = await cityStore.loadCities()
        let savedSelected = await cityStore.loadSelectedCity()
        let cached = await weatherCacheStore.loadCache()

        cities = savedCities
        selectedCity = savedSelected ?? savedCities.first

        // Keep selected city consistent.
        if let selectedCity, !cities.contains(selectedCity) {
            self.selectedCity = cities.first
        }

        // Prime weather state map from cache so we can render immediately.
        for city in cities {
            if let payload = cached[city] {
                weatherByCity[city] = .loaded(payload)
            } else if weatherByCity[city] == nil {
                weatherByCity[city] = .idle
            }
        }

        refreshAllCities()
    }

    func selectCity(_ city: String) {
        selectedCity = city
        Task { [cityStore] in
            await cityStore.saveSelectedCity(city)
        }

        // Always refresh when switching cities (hot update behavior).
        fetchWeather(for: city)
    }

    func addCity(_ city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var next = cities.filter { $0 != trimmed }
        next.append(trimmed)
        cities = next

        // Ensure we have a state entry.
        if weatherByCity[trimmed] == nil {
            weatherByCity[trimmed] = .idle
        }

        selectedCity = trimmed
        Task { [cityStore, next] in
            await cityStore.saveCities(next)
            await cityStore.saveSelectedCity(trimmed)
        }
        fetchWeather(for: trimmed)
    }

    func removeCity(_ city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard cities.contains(trimmed) else { return }

        tasks[trimmed]?.cancel()
        tasks[trimmed] = nil
        refreshingCities.remove(trimmed)
        weatherByCity.removeValue(forKey: trimmed)

        let next = cities.filter { $0 != trimmed }
        cities = next

        if selectedCity == trimmed {
            selectedCity = next.first
        }

        Task { [cityStore, weatherCacheStore, next, selectedCity] in
            await cityStore.saveCities(next)
            await cityStore.saveSelectedCity(selectedCity)
            await weatherCacheStore.remove(city: trimmed)
        }
    }

    func refreshAllCities() {
        for city in cities {
            fetchWeather(for: city)
        }
    }

    func fetchWeather(for city: String) {
        tasks[city]?.cancel()
        let previous = weatherByCity[city]
        refreshingCities.insert(city)
        if previous == nil {
            weatherByCity[city] = .idle
        }

        tasks[city] = Task { [weak self] in
            do {
                let payload = try await self?.weatherProvider.weather(for: city)
                guard let payload else { return }
                if Task.isCancelled { return }
                self?.refreshingCities.remove(city)
                self?.weatherByCity[city] = .loaded(payload)
                Task { [weatherCacheStore] in
                    await weatherCacheStore.save(city: city, payload: payload)
                }
            } catch {
                if Task.isCancelled { return }
                self?.refreshingCities.remove(city)

                // If we were refreshing an already-loaded city, keep the previous data to avoid UI flashing.
                switch previous {
                case .loaded:
                    break
                default:
                    self?.weatherByCity[city] = .failed(error.localizedDescription)
                }
            }
        }
    }

    func refreshSelectedCity() {
        guard let selectedCity else { return }
        fetchWeather(for: selectedCity)
    }
}
