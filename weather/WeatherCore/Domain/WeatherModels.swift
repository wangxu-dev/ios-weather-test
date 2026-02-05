//
//  WeatherModels.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct WeatherPayload: Codable {
    let weatherInfo: WeatherInfo?
    let hourly: HourlyForecast?
    let daily: DailyForecast?
}

struct WeatherInfo: Codable {
    let city: String
    let updateTime: String
    /// Current temperature.
    let tempCurrent: String?
    let tempHigh: String
    let tempLow: String
    let weather: String
    let weatherCode: Int?
    let isDay: Bool?
    let windDirection: String
    let windScale: String
    let windDegrees: Double?
    let windSpeedMetersPerSecond: Double?
    let windGustMetersPerSecond: Double?
    let feelsLike: String?
    let humidity: String?
    let humidityPercent: Int?
    let precipitation: String?
    let precipitationMm: Double?
    let pressure: String?
    let visibility: String?
    let windGust: String?
    let uvIndexMax: String?
    let uvIndexMaxValue: Double?
    let sunrise: String?
    let sunset: String?
}

struct HourlyForecast: Codable, Sendable {
    let time: [String]
    let temperature2m: [Double]
    let precipitationProbability: [Int]?
    let precipitation: [Double]?
    let weatherCode: [Int]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case weatherCode = "weather_code"
    }
}

struct DailyForecast: Codable, Sendable {
    let time: [String]
    let temperature2mMax: [Double]?
    let temperature2mMin: [Double]?
    let weatherCode: [Int]?
    let sunrise: [String]?
    let sunset: [String]?
    let uvIndexMax: [Double]?
    let precipitationSum: [Double]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case weatherCode = "weather_code"
        case sunrise
        case sunset
        case uvIndexMax = "uv_index_max"
        case precipitationSum = "precipitation_sum"
    }
}
