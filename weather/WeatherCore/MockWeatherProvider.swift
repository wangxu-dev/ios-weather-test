//
//  MockWeatherProvider.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

struct MockWeatherProvider: WeatherProviding {
    func weather(for city: String) async throws -> WeatherPayload {
        WeatherPayload(
            weatherInfo: WeatherInfo(
                city: city,
                updateTime: "2026-01-25 12:00:00",
                tempHigh: "10",
                tempLow: "0",
                weather: "晴",
                windDirection: "西北风",
                windScale: "3级"
            ),
            alarms: [
                WeatherAlarm(
                    title: "大风蓝色预警",
                    type: "大风 蓝色预警",
                    publishTime: "2026-01-25 09:00",
                    details: "示例：未来 12 小时有大风。"
                ),
            ]
        )
    }
}

