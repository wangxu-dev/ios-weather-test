//
//  CityRecommendationViewModel.swift
//  weather
//

import Foundation
import Combine

@MainActor
final class CityRecommendationViewModel: ObservableObject {
    @Published private(set) var recommendedCity: String? = nil
    @Published private(set) var rawLocationText: String? = nil
    @Published private(set) var isLoading: Bool = false

    private let matcher: any CityAutoMatching
    private var task: Task<Void, Never>?
    private var lastUpdatedAt: Date?

    init(matcher: any CityAutoMatching) {
        self.matcher = matcher
    }

    func refreshIfNeeded(maxAge: TimeInterval = 60 * 10) {
        if let lastUpdatedAt, Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }
        refresh()
    }

    func refresh() {
        task?.cancel()
        isLoading = true

        #if DEBUG
        print("[CityRecommendationVM] refresh()")
        #endif

        task = Task { [weak self] in
            do {
                guard let self else { return }
                let result = try await self.matcher.resolveCity()
                if Task.isCancelled { return }
                self.recommendedCity = result.matchedCity
                self.rawLocationText = result.rawLocationText
                self.isLoading = false
                self.lastUpdatedAt = Date()
                #if DEBUG
                print("[CityRecommendationVM] done matched=\(result.matchedCity ?? "nil") raw=\(result.rawLocationText) candidates=\(result.locatedCandidates) suggested=\(result.suggestedCities)")
                #endif
            } catch {
                if Task.isCancelled { return }
                guard let self else { return }
                self.recommendedCity = nil
                self.rawLocationText = nil
                self.isLoading = false
                self.lastUpdatedAt = Date()
                #if DEBUG
                print("[CityRecommendationVM] failed error=\(error.localizedDescription)")
                #endif
            }
        }
    }
}
