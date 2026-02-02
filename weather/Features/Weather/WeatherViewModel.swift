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

    @Published var city: String = ""
    @Published private(set) var state: State = .idle
    @Published private(set) var citySuggestions: [String] = []

    private let weatherProvider: any WeatherProviding
    private let citySuggester: any CitySuggesting
    private var currentTask: Task<Void, Never>?
    private var suggestionsTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(weatherProvider: any WeatherProviding, citySuggester: any CitySuggesting) {
        self.weatherProvider = weatherProvider
        self.citySuggester = citySuggester

        $city
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSuggestions(for: value)
            }
            .store(in: &cancellables)
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
}
