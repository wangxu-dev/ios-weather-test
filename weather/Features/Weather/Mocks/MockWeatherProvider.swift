//
//  MockWeatherProvider.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct MockWeatherProvider: WeatherProviding {
    func weather(for place: Place) async throws -> WeatherPayload {
        WeatherPayload(
            weatherInfo: WeatherInfo(
                city: place.displayName,
                updateTime: "2026-01-25 12:00:00",
                tempCurrent: "6",
                tempHigh: "10",
                tempLow: "0",
                weather: "晴",
                windDirection: "西北风",
                windScale: "3级"
            )
        )
    }
}
