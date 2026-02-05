//
//  WeatherComCnCitySuggester.swift
//  weather
//

import Foundation

final class WeatherComCnCitySuggester: CitySuggesting {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func suggestions(matching query: String, limit: Int) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let list = try await openMeteoGeocoding(query: trimmed, limit: limit)
        return list
    }

    private func openMeteoGeocoding(query: String, limit: Int) async throws -> [Place] {
        struct Envelope: Decodable {
            struct Result: Decodable {
                let name: String
                let latitude: Double
                let longitude: Double
                let country: String?
                let admin1: String?
            }
            let results: [Result]?
        }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(max(1, min(20, limit)))),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json"),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherAPIError(message: "城市搜索失败。")
        }

        let decoded = try JSONDecoder().decode(Envelope.self, from: data)
        let results = decoded.results ?? []

        // De-duplicate by place id while preserving order.
        var seen = Set<String>()
        var places: [Place] = []
        for item in results {
            let place = Place(
                name: item.name,
                country: item.country,
                admin1: item.admin1,
                latitude: item.latitude,
                longitude: item.longitude
            )
            if seen.insert(place.id).inserted {
                places.append(place)
            }
            if places.count >= max(0, limit) { break }
        }

        return places
    }
}
