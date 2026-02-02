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

    private let citySuggester: any CitySuggesting
    private var cancellables: Set<AnyCancellable> = []
    private var task: Task<Void, Never>?

    init(citySuggester: any CitySuggesting) {
        self.citySuggester = citySuggester

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSuggestions(for: value)
            }
            .store(in: &cancellables)
    }

    func clear() {
        query = ""
        suggestions = []
        task?.cancel()
        task = nil
    }

    private func updateSuggestions(for query: String) {
        task?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        task = Task { [weak self] in
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

