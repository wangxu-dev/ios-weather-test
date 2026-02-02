//
//  WeatherModels.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct WeatherPayload: Decodable {
    let weatherInfo: WeatherInfo?
    let alarms: [WeatherAlarm]
}

struct WeatherInfo: Decodable {
    let city: String
    let updateTime: String
    let tempHigh: String
    let tempLow: String
    let weather: String
    let windDirection: String
    let windScale: String
}

struct WeatherAlarm: Decodable, Identifiable {
    var id: String { "\(publishTime)|\(title)" }

    let title: String
    let type: String
    let publishTime: String
    let details: String
}
