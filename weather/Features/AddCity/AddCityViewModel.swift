//
//  AddCityViewModel.swift
//  weather
//

import Foundation
import Combine

@MainActor
final class AddCityViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var suggestions: [Place] = []

    private let citySuggester: any CitySuggesting
    private var cancellables: Set<AnyCancellable> = []
    private var suggestionsTask: Task<Void, Never>?

    init(citySuggester: any CitySuggesting) {
        self.citySuggester = citySuggester

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSuggestions(for: value)
            }
            .store(in: &cancellables)
    }

    private func updateSuggestions(for query: String) {
        suggestionsTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        if trimmed.count < 2 {
            // Keep UI calm for 1-character queries.
            return
        }

        suggestionsTask = Task { [weak self] in
            do {
                let list = try await self?.citySuggester.suggestions(matching: trimmed, limit: 20) ?? []
                if Task.isCancelled { return }
                self?.suggestions = list
            } catch {
                if Task.isCancelled { return }
                self?.suggestions = []
            }
        }
    }
}
