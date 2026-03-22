import Foundation

nonisolated protocol WeatherRepository: Sendable {
    func fetchWeather(for placeID: PlaceID) async throws -> WeatherSnapshot
}

nonisolated protocol PlaceRepository: Sendable {
    func search(query: String, limit: Int) async throws -> [Place]
    func resolveCurrentLocation() async throws -> Place
    func place(for id: PlaceID) async -> Place?
}

nonisolated protocol PlacePersistence: Sendable {
    func loadPlaces() async -> [Place]
    func savePlaces(_ places: [Place]) async
    func loadSelectedPlaceID() async -> PlaceID?
    func saveSelectedPlaceID(_ id: PlaceID?) async
}

nonisolated protocol WeatherCachePersistence: Sendable {
    func load() async -> [PlaceID: WeatherSnapshot]
    func save(snapshot: WeatherSnapshot, for id: PlaceID) async
    func remove(for id: PlaceID) async
}
