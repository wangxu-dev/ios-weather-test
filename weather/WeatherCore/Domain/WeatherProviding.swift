//
//  WeatherProviding.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import Foundation

protocol WeatherProviding {
    func weather(for place: Place) async throws -> WeatherPayload
}

struct WeatherAPIError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
