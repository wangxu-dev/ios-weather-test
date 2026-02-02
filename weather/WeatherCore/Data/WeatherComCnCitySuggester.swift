//
//  WeatherComCnCitySuggester.swift
//  weather
//

import Foundation

final class WeatherComCnCitySuggester: CitySuggesting {
    private let session: URLSession
    private let cityListCache: CityListCaching

    init(session: URLSession = .shared, cityListCache: CityListCaching = InMemoryCityListCache.shared) {
        self.session = session
        self.cityListCache = cityListCache
    }

    func suggestions(matching query: String, limit: Int) async throws -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let cities = try await loadCityList()
        let names = cities.values.map { $0.n }
        let matches = names.filter { $0.contains(trimmed) }

        // De-duplicate and sort for better UX:
        // 1) Prefix match first
        // 2) Shorter names first
        // 3) Lexicographic as a stable tie-breaker
        var seen = Set<String>()
        let deduped = matches.filter { seen.insert($0).inserted }
        let sorted = deduped.sorted {
            let aPrefix = $0.hasPrefix(trimmed)
            let bPrefix = $1.hasPrefix(trimmed)
            if aPrefix != bPrefix { return aPrefix && !bPrefix }
            if $0.count != $1.count { return $0.count < $1.count }
            return $0 < $1
        }

        return Array(sorted.prefix(max(0, limit)))
    }

    private func loadCityList() async throws -> [String: WeatherComCnCityInfo] {
        if let cached = await cityListCache.getCachedCityList() {
            return cached
        }

        var components = URLComponents(string: "https://i.tq121.com.cn/j/webgis_v2/city.json")!
        components.queryItems = [
            URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000))),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10
        request.setValue("https://www.weather.com.cn/", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherAPIError(message: "查询城市列表失败。")
        }

        let text = String(decoding: data, as: UTF8.self)
        let jsonText = stripJSONP(prefix: "weacity(", suffix: ")", from: text)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw WeatherAPIError(message: "城市列表内容不是 UTF-8。")
        }

        let cities = try JSONDecoder().decode([String: WeatherComCnCityInfo].self, from: jsonData)
        await cityListCache.setCachedCityList(cities)
        return cities
    }

    private func stripJSONP(prefix: String, suffix: String, from text: String) -> String {
        var result = text
        if result.hasPrefix(prefix) { result.removeFirst(prefix.count) }
        if result.hasSuffix(suffix) { result.removeLast(suffix.count) }
        return result
    }
}
