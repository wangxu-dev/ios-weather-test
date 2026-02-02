//
//  WeatherComCnClient.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

/// Swift port of the logic in `weather_api/main.go`, but calling the upstream endpoints directly.
///
/// Flow:
/// 1) Fetch city list JSONP, find cityId by exact name match
/// 2) Fetch weather page and parse embedded JSON fragments
final class WeatherComCnClient: WeatherProviding {
    private struct WeatherInfoEnvelope: Decodable {
        let weatherinfo: WeatherInfoDTO
    }

    private struct WeatherInfoDTO: Decodable {
        let cityname: String
        let fctime: String
        let temp: String
        let tempn: String
        let weather: String
        let wd: String
        let ws: String
    }

    private struct AlarmEnvelope: Decodable {
        let w: [AlarmDTO]?
    }

    private struct AlarmDTO: Decodable {
        let w1: String?
        let w5: String?
        let w7: String?
        let w8: String?
        let w9: String?
        let w13: String?
    }

    private let session: URLSession
    private let cityListCache: CityListCaching

    init(session: URLSession = .shared, cityListCache: CityListCaching = InMemoryCityListCache.shared) {
        self.session = session
        self.cityListCache = cityListCache
    }

    func weather(for city: String) async throws -> WeatherPayload {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WeatherAPIError(message: "城市名不能为空。")
        }

        guard let cityId = try await fetchCityId(cityName: trimmed) else {
            throw WeatherAPIError(message: "城市 '\(trimmed)' 未找到。")
        }

        return try await fetchWeather(cityId: cityId)
    }

    private func fetchCityId(cityName: String) async throws -> String? {
        if let cachedCities = await cityListCache.getCachedCityList() {
            if let cityId = cachedCities.first(where: { $0.value.n == cityName })?.key {
                return cityId
            }
            return nil
        }

        // Example: https://i.tq121.com.cn/j/webgis_v2/city.json?_=TIMESTAMP
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
        for (cityId, info) in cities where info.n == cityName {
            return cityId
        }
        return nil
    }

    private func fetchWeather(cityId: String) async throws -> WeatherPayload {
        // Example: https://d1.weather.com.cn/dingzhi/101010100.html?_=TIMESTAMP
        var components = URLComponents(string: "https://d1.weather.com.cn/dingzhi/\(cityId).html")!
        components.queryItems = [
            URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000))),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10
        request.setValue("https://www.weather.com.cn/", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherAPIError(message: "获取天气数据失败。")
        }

        let text = String(decoding: data, as: UTF8.self)
        let parts = text.split(separator: ";", omittingEmptySubsequences: true)

        var weatherInfo: WeatherInfo?
        var alarms: [WeatherAlarm] = []

        if let first = parts.first, first.contains("{") {
            let json = substringFromFirstBrace(String(first))
            if let jsonData = json.data(using: .utf8) {
                let envelope = try JSONDecoder().decode(WeatherInfoEnvelope.self, from: jsonData)
                weatherInfo = WeatherInfo(
                    city: envelope.weatherinfo.cityname,
                    updateTime: formatYYYYMMDDHHmm(envelope.weatherinfo.fctime),
                    tempHigh: envelope.weatherinfo.temp,
                    tempLow: envelope.weatherinfo.tempn,
                    weather: envelope.weatherinfo.weather,
                    windDirection: envelope.weatherinfo.wd,
                    windScale: envelope.weatherinfo.ws
                )
            }
        }

        if parts.count > 1, parts[1].contains("{") {
            let json = substringFromFirstBrace(String(parts[1]))
            if let jsonData = json.data(using: .utf8) {
                let envelope = try JSONDecoder().decode(AlarmEnvelope.self, from: jsonData)
                let items = envelope.w ?? []
                alarms = items.compactMap { dto in
                    guard
                        let title = dto.w13, !title.isEmpty,
                        let typeA = dto.w5, !typeA.isEmpty,
                        let typeB = dto.w7, !typeB.isEmpty,
                        let publishTime = dto.w8, !publishTime.isEmpty,
                        let details = dto.w9, !details.isEmpty
                    else {
                        return nil
                    }
                    return WeatherAlarm(
                        title: title,
                        type: "\(typeA) \(typeB)预警",
                        publishTime: publishTime,
                        details: details
                    )
                }
            }
        }

        return WeatherPayload(weatherInfo: weatherInfo, alarms: alarms)
    }

    private func stripJSONP(prefix: String, suffix: String, from text: String) -> String {
        var result = text
        if result.hasPrefix(prefix) { result.removeFirst(prefix.count) }
        if result.hasSuffix(suffix) { result.removeLast(suffix.count) }
        return result
    }

    private func substringFromFirstBrace(_ text: String) -> String {
        guard let idx = text.firstIndex(of: "{") else { return text }
        return String(text[idx...])
    }

    /// Input: "YYYYMMDDHHmm" (12 chars)
    /// Output: "YYYY-MM-DD HH:mm:00"
    private func formatYYYYMMDDHHmm(_ text: String) -> String {
        guard text.count == 12 else { return text }
        let chars = Array(text)
        let yyyy = String(chars[0..<4])
        let mm = String(chars[4..<6])
        let dd = String(chars[6..<8])
        let hh = String(chars[8..<10])
        let mi = String(chars[10..<12])
        return "\(yyyy)-\(mm)-\(dd) \(hh):\(mi):00"
    }
}
