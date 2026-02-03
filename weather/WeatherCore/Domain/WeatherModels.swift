//
//  WeatherModels.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct WeatherPayload: Codable {
    let weatherInfo: WeatherInfo?
    let alarms: [WeatherAlarm]
}

struct WeatherInfo: Codable {
    let city: String
    let updateTime: String
    let tempHigh: String
    let tempLow: String
    let weather: String
    let windDirection: String
    let windScale: String
}

struct WeatherAlarm: Codable, Identifiable {
    var id: String { "\(publishTime)|\(title)" }

    let title: String
    let type: String
    let publishTime: String
    let details: String
}
