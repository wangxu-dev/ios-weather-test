//
//  WeatherComCnClient.swift
//  weather
//
//  NOTE: The app has been migrated to Open‑Meteo. The filename is kept to avoid
//  touching the Xcode project file list.
//

import Foundation

/// Open‑Meteo forecast client (geocoding + forecast).
///
/// Flow:
/// 1) Search place by name with Open‑Meteo Geocoding API
/// 2) Fetch forecast by coordinates with Open‑Meteo Forecast API
final class OpenMeteoClient: WeatherProviding {
    private struct GeocodingEnvelope: Decodable {
        let results: [GeocodingResult]?
    }

    private struct GeocodingResult: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }

    private struct ForecastEnvelope: Decodable {
        let timezone: String?
        let current: Current?
        let daily: Daily?
    }

    private struct Current: Decodable {
        let time: String
        let temperature2m: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let windDirection10m: Double

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
        }
    }

    private struct Daily: Decodable {
        let temperature2mMax: [Double]?
        let temperature2mMin: [Double]?

        enum CodingKeys: String, CodingKey {
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func weather(for city: String) async throws -> WeatherPayload {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WeatherAPIError(message: "城市名不能为空。")
        }

        let place = try await geocode(cityName: trimmed)
        let forecast = try await forecast(latitude: place.latitude, longitude: place.longitude)

        guard let current = forecast.current else {
            throw WeatherAPIError(message: "没有拿到 current 天气数据。")
        }

        let maxTemp = forecast.daily?.temperature2mMax?.first
        let minTemp = forecast.daily?.temperature2mMin?.first

        let info = WeatherInfo(
            city: place.name,
            updateTime: formatTime(current.time),
            tempCurrent: formatTemp(current.temperature2m),
            tempHigh: formatTemp(maxTemp ?? current.temperature2m),
            tempLow: formatTemp(minTemp ?? current.temperature2m),
            weather: weatherText(weatherCode: current.weatherCode),
            windDirection: windDirectionText(degrees: current.windDirection10m),
            windScale: windScaleText(speedMetersPerSecond: current.windSpeed10m)
        )

        return WeatherPayload(weatherInfo: info)
    }

    private func geocode(cityName: String) async throws -> GeocodingResult {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: cityName),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json"),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherAPIError(message: "地理编码失败。")
        }

        let decoded = try JSONDecoder().decode(GeocodingEnvelope.self, from: data)
        guard let place = decoded.results?.first else {
            throw WeatherAPIError(message: "城市 '\(cityName)' 未找到。")
        }
        return place
    }

    private func forecast(latitude: Double, longitude: Double) async throws -> ForecastEnvelope {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,wind_direction_10m"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherAPIError(message: "获取天气数据失败。")
        }

        return try JSONDecoder().decode(ForecastEnvelope.self, from: data)
    }

    private func formatTemp(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private func formatTime(_ value: String) -> String {
        // Open‑Meteo commonly returns "YYYY-MM-DDTHH:mm". Normalize for UI.
        value.replacingOccurrences(of: "T", with: " ")
    }

    private func weatherText(weatherCode: Int) -> String {
        // WMO weather interpretation codes (simplified Chinese).
        switch weatherCode {
        case 0:
            return "晴"
        case 1:
            return "基本晴朗"
        case 2:
            return "多云"
        case 3:
            return "阴"
        case 45, 48:
            return "雾"
        case 51, 53, 55:
            return "毛毛雨"
        case 56, 57:
            return "冻毛毛雨"
        case 61, 63, 65:
            return "雨"
        case 66, 67:
            return "冻雨"
        case 71, 73, 75:
            return "雪"
        case 77:
            return "雪粒"
        case 80, 81, 82:
            return "阵雨"
        case 85, 86:
            return "阵雪"
        case 95:
            return "雷暴"
        case 96, 99:
            return "强雷暴"
        default:
            return "未知"
        }
    }

    private func windDirectionText(degrees: Double) -> String {
        // 16-wind compass, localized to Chinese.
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let idx = Int((normalized / 22.5).rounded()) % 16
        switch idx {
        case 0: return "北风"
        case 1: return "北东北风"
        case 2: return "东北风"
        case 3: return "东东北风"
        case 4: return "东风"
        case 5: return "东东南风"
        case 6: return "东南风"
        case 7: return "南东南风"
        case 8: return "南风"
        case 9: return "南西南风"
        case 10: return "西南风"
        case 11: return "西西南风"
        case 12: return "西风"
        case 13: return "西西北风"
        case 14: return "西北风"
        case 15: return "北西北风"
        default: return "风"
        }
    }

    private func windScaleText(speedMetersPerSecond: Double) -> String {
        // Beaufort scale (roughly) based on m/s.
        let v = max(0, speedMetersPerSecond)
        let scale: Int
        switch v {
        case ..<0.3: scale = 0
        case ..<1.6: scale = 1
        case ..<3.4: scale = 2
        case ..<5.5: scale = 3
        case ..<8.0: scale = 4
        case ..<10.8: scale = 5
        case ..<13.9: scale = 6
        case ..<17.2: scale = 7
        case ..<20.8: scale = 8
        case ..<24.5: scale = 9
        case ..<28.5: scale = 10
        case ..<32.7: scale = 11
        default: scale = 12
        }
        return "\(scale)级"
    }
}
