//
//  weatherApp.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import SwiftUI

@main
struct WeatherApp: App {
    private let weatherProvider = WeatherComCnClient()

    var body: some Scene {
        WindowGroup {
            ContentView(weatherProvider: weatherProvider)
        }
    }
}
