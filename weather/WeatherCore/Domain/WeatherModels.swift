//
//  WeatherModels.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct WeatherPayload: Codable {
    let weatherInfo: WeatherInfo?
}

struct WeatherInfo: Codable {
    let city: String
    let updateTime: String
    /// Current temperature.
    let tempCurrent: String?
    let tempHigh: String
    let tempLow: String
    let weather: String
    let windDirection: String
    let windScale: String
}
