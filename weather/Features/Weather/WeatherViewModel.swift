//
//  WeatherViewModel.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(WeatherPayload)
        case failed(String)
    }
    
    enum OverlayKind {
        case none
        case history
        case suggestions
    }

    @Published var city: String = ""
    @Published private(set) var state: State = .idle
    @Published private(set) var citySuggestions: [String] = []
    @Published private(set) var recentCities: [String] = []
    @Published private(set) var isSearchFocused: Bool = false

    private let weatherProvider: any WeatherProviding
    private let citySuggester: any CitySuggesting
    private let recentCitiesStore: any RecentCitiesStoring
    private var currentTask: Task<Void, Never>?
    private var suggestionsTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        weatherProvider: any WeatherProviding,
        citySuggester: any CitySuggesting,
        recentCitiesStore: any RecentCitiesStoring
    ) {
        self.weatherProvider = weatherProvider
        self.citySuggester = citySuggester
        self.recentCitiesStore = recentCitiesStore

        Task { [weak self] in
            let loaded = await recentCitiesStore.load()
            self?.recentCities = loaded
        }

        $city
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSuggestions(for: value)
            }
            .store(in: &cancellables)
    }
    
    func setSearchFocused(_ isFocused: Bool) {
        isSearchFocused = isFocused
        if !isFocused {
            citySuggestions = []
        }
    }
    
    var overlayKind: OverlayKind {
        guard isSearchFocused else { return .none }
        
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !citySuggestions.isEmpty {
            return .suggestions
        }
        if trimmed.isEmpty, !recentCities.isEmpty {
            return .history
        }
        return .none
    }
    
    var shouldShowContent: Bool {
        // Keep sections separated: when the search overlay is visible, don't show content.
        guard overlayKind == .none else { return false }
        switch state {
        case .idle:
            return false
        case .loading, .loaded, .failed:
            return true
        }
    }

    func fetchWeather() {
        currentTask?.cancel()

        let city = city
        citySuggestions = []
        state = .loading

        currentTask = Task { [weak self] in
            do {
                let payload = try await self?.weatherProvider.weather(for: city)
                guard let payload else { return }
                self?.recordRecentCity(city)
                self?.state = .loaded(payload)
            } catch {
                if Task.isCancelled { return }
                self?.state = .failed(error.localizedDescription)
            }
        }
    }

    func selectSuggestion(_ cityName: String) {
        city = cityName
        citySuggestions = []
        fetchWeather()
    }

    func selectRecentCity(_ cityName: String) {
        city = cityName
        citySuggestions = []
        fetchWeather()
    }

    private func updateSuggestions(for query: String) {
        suggestionsTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            citySuggestions = []
            return
        }

        suggestionsTask = Task { [weak self] in
            do {
                let suggestions = try await self?.citySuggester.suggestions(matching: trimmed, limit: 8) ?? []
                if Task.isCancelled { return }
                self?.citySuggestions = suggestions
            } catch {
                // Suggestions should not break the main flow.
                if Task.isCancelled { return }
                self?.citySuggestions = []
            }
        }
    }

    private func recordRecentCity(_ cityName: String) {
        let trimmed = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var next = recentCities.filter { $0 != trimmed }
        next.insert(trimmed, at: 0)
        if next.count > 10 { next = Array(next.prefix(10)) }

        recentCities = next
        Task { [recentCitiesStore] in
            await recentCitiesStore.save(next)
        }
    }
}
