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
    private var tasks: [String: Task<Void, Never>] = [:]
    private var loadTask: Task<Void, Never>?

    init(weatherProvider: any WeatherProviding, cityStore: any CityListStoring) {
        self.weatherProvider = weatherProvider
        self.cityStore = cityStore

        loadTask = Task { [weak self] in
            await self?.loadFromDisk()
        }
    }

    func loadFromDisk() async {
        let savedCities = await cityStore.loadCities()
        let savedSelected = await cityStore.loadSelectedCity()

        cities = savedCities
        selectedCity = savedSelected ?? savedCities.first

        // Keep selected city consistent.
        if let selectedCity, !cities.contains(selectedCity) {
            self.selectedCity = cities.first
        }

        // Prime weather state map.
        for city in cities where weatherByCity[city] == nil {
            weatherByCity[city] = .idle
        }

        if let selected = selectedCity {
            fetchWeather(for: selected)
        }
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

    func fetchWeather(for city: String) {
        tasks[city]?.cancel()
        let previous = weatherByCity[city]
        let hadLoaded: Bool
        switch previous {
        case .loaded:
            hadLoaded = true
        default:
            hadLoaded = false
        }

        if hadLoaded {
            refreshingCities.insert(city)
        } else {
            weatherByCity[city] = .loading
        }

        tasks[city] = Task { [weak self] in
            do {
                let payload = try await self?.weatherProvider.weather(for: city)
                guard let payload else { return }
                if Task.isCancelled { return }
                self?.refreshingCities.remove(city)
                self?.weatherByCity[city] = .loaded(payload)
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
