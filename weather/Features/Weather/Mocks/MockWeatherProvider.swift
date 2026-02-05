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
                weatherCode: 0,
                isDay: true,
                windDirection: "西北风",
                windScale: "3级",
                feelsLike: "5",
                humidity: "35%",
                precipitation: "0 mm",
                pressure: "1021 hPa",
                visibility: "10.0 km",
                windGust: "6.0 m/s",
                uvIndexMax: "3.5",
                sunrise: "2026-01-25 07:08",
                sunset: "2026-01-25 17:23"
            ),
            hourly: nil,
            daily: nil
        )
    }
}
