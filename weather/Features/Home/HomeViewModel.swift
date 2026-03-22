import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum SearchStatus: Equatable {
        case idle
        case searching
        case empty
        case results
        case error(String)
    }

    private let useCase: HomeUseCase
    private let aiProvider: AIWeatherAssistantProviding

    var places: [Place] = []
    var selectedPlaceID: PlaceID?
    var weatherStates: [PlaceID: WeatherLoadState] = [:]
    var refreshingPlaceIDs: Set<PlaceID> = []

    var isSearchPresented = false
    var searchQuery = ""
    var suggestions: [Place] = []
    var searchStatus: SearchStatus = .idle

    var bannerMessage: String?
    var aiSummary: AISummary?

    private var refreshTasks: [PlaceID: Task<Void, Never>] = [:]

    init(useCase: HomeUseCase, aiProvider: AIWeatherAssistantProviding) {
        self.useCase = useCase
        self.aiProvider = aiProvider
    }

    func start() async {
        let initial = await useCase.bootstrap()
        self.places = initial.places
        self.selectedPlaceID = initial.selectedID
        self.weatherStates = initial.states

        if selectedPlaceID == nil {
            selectedPlaceID = places.first?.id
        }

        await refreshAllIfNeeded(force: false)
    }

    func refreshAllIfNeeded(force: Bool) async {
        for place in places {
            guard force || shouldRefresh(place.id) else { continue }
            await refresh(placeID: place.id)
        }
    }

    func refreshSelected() async {
        guard let selectedPlaceID else { return }
        await refresh(placeID: selectedPlaceID)
    }

    func refresh(placeID: PlaceID) async {
        refreshTasks[placeID]?.cancel()
        refreshingPlaceIDs.insert(placeID)
        if weatherStates[placeID] == nil {
            weatherStates[placeID] = .loading
        }

        let previous = weatherStates[placeID]
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                self.weatherStates[placeID] = .loading
                let snapshot = try await useCase.refresh(placeID: placeID)
                if Task.isCancelled { return }
                self.weatherStates[placeID] = .loaded(snapshot, isStale: false)
                self.refreshingPlaceIDs.remove(placeID)
                await self.updateAISummaryIfNeeded(placeID: placeID, snapshot: snapshot)
            } catch {
                if Task.isCancelled { return }
                self.refreshingPlaceIDs.remove(placeID)
                if case .loaded(let snapshot, _) = previous {
                    self.weatherStates[placeID] = .loaded(snapshot, isStale: true)
                } else {
                    self.weatherStates[placeID] = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                }
            }
        }

        refreshTasks[placeID] = task
        await task.value
    }

    func select(placeID: PlaceID) {
        selectedPlaceID = placeID
        Task {
            await useCase.persist(places: places, selectedID: selectedPlaceID)
        }
    }

    func remove(placeID: PlaceID) {
        refreshTasks[placeID]?.cancel()
        refreshTasks[placeID] = nil
        refreshingPlaceIDs.remove(placeID)

        places.removeAll { $0.id == placeID }
        weatherStates.removeValue(forKey: placeID)

        if selectedPlaceID == placeID {
            selectedPlaceID = places.first?.id
        }

        Task {
            await useCase.removeCache(for: placeID)
            await useCase.persist(places: places, selectedID: selectedPlaceID)
        }
    }

    func addOrSelect(place: Place) {
        if places.contains(where: { $0.id == place.id }) {
            select(placeID: place.id)
        } else {
            if place.isCurrentLocation {
                places.removeAll { $0.isCurrentLocation }
                places.insert(place, at: 0)
            } else {
                places.append(place)
            }
            weatherStates[place.id] = .idle
            select(placeID: place.id)
            Task {
                await useCase.persist(places: places, selectedID: selectedPlaceID)
                await refresh(placeID: place.id)
            }
        }
        hideSearch()
    }

    func resolveCurrentLocationAndAdd() async {
        do {
            let place = try await useCase.resolveCurrentLocation()
            addOrSelect(place: place)
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func handleSearchQueryChanged() async {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            searchStatus = .idle
            return
        }

        searchStatus = .searching
        do {
            try await Task.sleep(nanoseconds: 250_000_000)
            let list = try await useCase.searchCity(query: trimmed, limit: 20)
            if list.isEmpty {
                searchStatus = .empty
            } else {
                searchStatus = .results
            }
            suggestions = list
        } catch {
            searchStatus = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            suggestions = []
        }
    }

    func showSearch() {
        isSearchPresented = true
    }

    func hideSearch() {
        isSearchPresented = false
        searchQuery = ""
        suggestions = []
        searchStatus = .idle
    }

    var selectedPlace: Place? {
        guard let selectedPlaceID else { return places.first }
        return places.first(where: { $0.id == selectedPlaceID })
    }

    var selectedViewData: HomeWeatherViewData? {
        guard let place = selectedPlace else { return nil }
        guard case .loaded(let snapshot, let isStale) = weatherStates[place.id] else { return nil }
        return HomeWeatherViewDataMapper.map(snapshot: snapshot, isStale: isStale)
    }

    var selectedState: WeatherLoadState {
        guard let id = selectedPlace?.id else { return .idle }
        return weatherStates[id] ?? .idle
    }

    private func shouldRefresh(_ placeID: PlaceID) -> Bool {
        if case .loaded(let snapshot, _) = weatherStates[placeID] {
            return snapshot.isExpired
        }
        return true
    }

    private func updateAISummaryIfNeeded(placeID: PlaceID, snapshot: WeatherSnapshot) async {
        guard selectedPlaceID == placeID else { return }
        let context = UserContext(localeIdentifier: Locale.current.identifier, prefersConcise: true)
        aiSummary = try? await aiProvider.summarize(snapshot: snapshot, context: context)
    }
}
