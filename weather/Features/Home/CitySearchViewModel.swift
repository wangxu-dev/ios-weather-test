//
//  CitySearchViewModel.swift
//  weather
//

import Foundation
import Combine

@MainActor
final class CitySearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isSearching: Bool = false
    /// The query string for which `suggestions` was last completed.
    /// Used by the UI to avoid showing "no results" for an outdated query and to prevent flicker.
    @Published private(set) var lastCompletedQuery: String = ""

    private let citySuggester: any CitySuggesting
    private var cancellables: Set<AnyCancellable> = []
    private var task: Task<Void, Never>?

    init(citySuggester: any CitySuggesting) {
        self.citySuggester = citySuggester

        $query
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] value in
                self?.immediateQueryDidChange(value)
            })
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSuggestions(for: value)
            }
            .store(in: &cancellables)
    }

    func clear() {
        query = ""
        suggestions = []
        isSearching = false
        lastCompletedQuery = ""
        task?.cancel()
        task = nil
    }

    private func immediateQueryDidChange(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions = []
            isSearching = false
            lastCompletedQuery = ""
            return
        }

        // Clear previous results as soon as the user changes the query,
        // so the UI does not show stale suggestions for a new input.
        suggestions = []
        isSearching = true
        lastCompletedQuery = ""
    }

    private func updateSuggestions(for query: String) {
        task?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            isSearching = false
            lastCompletedQuery = ""
            return
        }

        isSearching = true
        task = Task { [weak self] in
            do {
                let list = try await self?.citySuggester.suggestions(matching: trimmed, limit: 20) ?? []
                if Task.isCancelled { return }
                self?.suggestions = list
                self?.isSearching = false
                self?.lastCompletedQuery = trimmed
            } catch {
                if Task.isCancelled { return }
                self?.suggestions = []
                self?.isSearching = false
                self?.lastCompletedQuery = trimmed
            }
        }
    }
}
