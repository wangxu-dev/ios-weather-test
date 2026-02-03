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
    @Published private(set) var isDebouncing: Bool = false
    /// The query string for which `suggestions` was last completed.
    /// Used by the UI to avoid showing "no results" for an outdated query and to prevent flicker.
    @Published private(set) var lastCompletedQuery: String = ""

    private let citySuggester: any CitySuggesting
    private var cancellables: Set<AnyCancellable> = []
    private var task: Task<Void, Never>?

    init(citySuggester: any CitySuggesting) {
        self.citySuggester = citySuggester

        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] value in
                self?.queryDidChangeImmediately(value)
            })
            .debounce(for: .milliseconds(280), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.performSearch(for: value)
            }
            .store(in: &cancellables)
    }

    func clear() {
        query = ""
        suggestions = []
        isSearching = false
        isDebouncing = false
        lastCompletedQuery = ""
        task?.cancel()
        task = nil
    }

    private func queryDidChangeImmediately(_ trimmed: String) {
        task?.cancel()
        task = nil

        // While the user is typing, we debounce the actual search. Do not aggressively clear
        // UI state here; keeping the previous list avoids flicker.
        if trimmed.isEmpty {
            suggestions = []
            isSearching = false
            isDebouncing = false
            lastCompletedQuery = ""
            return
        }

        isDebouncing = true
        isSearching = false
    }

    private func performSearch(for trimmed: String) {
        task?.cancel()

        guard !trimmed.isEmpty else {
            suggestions = []
            isSearching = false
            isDebouncing = false
            lastCompletedQuery = ""
            return
        }

        isDebouncing = false
        isSearching = true
        task = Task { [weak self] in
            do {
                let list = try await self?.citySuggester.suggestions(matching: trimmed, limit: 20) ?? []
                if Task.isCancelled { return }
                self?.suggestions = list
                self?.isSearching = false
                self?.isDebouncing = false
                self?.lastCompletedQuery = trimmed
            } catch {
                if Task.isCancelled { return }
                self?.suggestions = []
                self?.isSearching = false
                self?.isDebouncing = false
                self?.lastCompletedQuery = trimmed
            }
        }
    }
}
