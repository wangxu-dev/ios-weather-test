import Foundation

nonisolated actor OpenMeteoPlaceRepository: PlaceRepository {
    private let session: URLSession
    private let locationProvider: any LocationProviding
    private var placeIndex: [PlaceID: Place] = [:]

    init(session: URLSession = .shared, locationProvider: any LocationProviding) {
        self.session = session
        self.locationProvider = locationProvider
    }

    func search(query: String, limit: Int) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: String(max(1, min(20, limit)))),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json"),
        ]

        let request = URLRequest(url: components.url!, timeoutInterval: 10)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.network("城市搜索失败")
        }

        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        let mapped = (decoded.results ?? []).map { OpenMeteoMapper.mapPlace($0) }

        var seen = Set<PlaceID>()
        var deduped: [Place] = []
        for item in mapped where seen.insert(item.id).inserted {
            deduped.append(item)
            placeIndex[item.id] = item
        }

        return deduped
    }

    func resolveCurrentLocation() async throws -> Place {
        let coordinate = try await locationProvider.requestCoordinate()
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/reverse")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json"),
        ]

        let request = URLRequest(url: components.url!, timeoutInterval: 10)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.network("当前位置解析失败")
        }

        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        if let first = decoded.results?.first {
            let resolved = OpenMeteoMapper.mapPlace(first, isCurrentLocation: true)
            placeIndex[resolved.id] = resolved
            return resolved
        }

        let fallback = Place(
            id: PlaceID(rawValue: "current-location"),
            name: "当前位置",
            coordinate: coordinate,
            isCurrentLocation: true
        )
        placeIndex[fallback.id] = fallback
        return fallback
    }

    func place(for id: PlaceID) async -> Place? {
        placeIndex[id]
    }

    func remember(_ places: [Place]) {
        for place in places {
            placeIndex[place.id] = place
        }
    }
}
