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

    @Published var city: String = "北京"
    @Published private(set) var state: State = .idle

    private let weatherProvider: any WeatherProviding
    private var currentTask: Task<Void, Never>?

    init(weatherProvider: any WeatherProviding) {
        self.weatherProvider = weatherProvider
    }

    func fetchWeather() {
        currentTask?.cancel()

        let city = city
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
}
