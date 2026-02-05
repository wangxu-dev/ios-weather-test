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

    func suggestions(matching query: String, limit: Int) async throws -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let list = try await openMeteoGeocoding(query: trimmed, limit: limit)
        // For now we only return the `name` for compatibility with existing storage/UI.
        // If you need to disambiguate same-name cities later, we'll refactor the app
        // to persist coordinates as a first-class location model.
        return list
    }

    private func openMeteoGeocoding(query: String, limit: Int) async throws -> [String] {
        struct Envelope: Decodable {
            struct Result: Decodable {
                let name: String
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
        let names = (decoded.results ?? []).map(\.name)

        // De-duplicate while preserving order.
        var seen = Set<String>()
        let deduped = names.filter { seen.insert($0).inserted }
        return Array(deduped.prefix(max(0, limit)))
    }
}
