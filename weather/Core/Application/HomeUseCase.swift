import Foundation

enum WeatherLoadState: Sendable {
    case idle
    case loading
    case loaded(WeatherSnapshot, isStale: Bool)
    case failed(String)
}

@MainActor
final class HomeUseCase {
    private let placeRepository: PlaceRepository
    private let weatherRepository: WeatherRepository
    private let placeStore: PlacePersistence
    private let cacheStore: WeatherCachePersistence

    init(
        placeRepository: PlaceRepository,
        weatherRepository: WeatherRepository,
        placeStore: PlacePersistence,
        cacheStore: WeatherCachePersistence
    ) {
        self.placeRepository = placeRepository
        self.weatherRepository = weatherRepository
        self.placeStore = placeStore
        self.cacheStore = cacheStore
    }

    func bootstrap() async -> (places: [Place], selectedID: PlaceID?, states: [PlaceID: WeatherLoadState]) {
        let savedPlaces = await placeStore.loadPlaces()
        let selectedID = await placeStore.loadSelectedPlaceID() ?? savedPlaces.first?.id
        let cache = await cacheStore.load()

        var states: [PlaceID: WeatherLoadState] = [:]
        for place in savedPlaces {
            if let snapshot = cache[place.id] {
                states[place.id] = .loaded(snapshot, isStale: snapshot.isExpired)
            } else {
                states[place.id] = .idle
            }
        }

        if let repo = placeRepository as? OpenMeteoPlaceRepository {
            await repo.remember(savedPlaces)
        }

        return (savedPlaces, selectedID, states)
    }

    func persist(places: [Place], selectedID: PlaceID?) async {
        await placeStore.savePlaces(places)
        await placeStore.saveSelectedPlaceID(selectedID)
    }

    func refresh(placeID: PlaceID) async throws -> WeatherSnapshot {
        let snapshot = try await weatherRepository.fetchWeather(for: placeID)
        await cacheStore.save(snapshot: snapshot, for: placeID)
        return snapshot
    }

    func removeCache(for id: PlaceID) async {
        await cacheStore.remove(for: id)
    }

    func resolveCurrentLocation() async throws -> Place {
        let place = try await placeRepository.resolveCurrentLocation()
        if let repo = placeRepository as? OpenMeteoPlaceRepository {
            await repo.remember([place])
        }
        return place
    }

    func searchCity(query: String, limit: Int) async throws -> [Place] {
        let list = try await placeRepository.search(query: query, limit: limit)
        if let repo = placeRepository as? OpenMeteoPlaceRepository {
            await repo.remember(list)
        }
        return list
    }
}
