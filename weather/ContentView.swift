//
//  ContentView.swift
//  weather
//
//  Kept as a thin wrapper so the app entry point stays simple.
//

import SwiftUI

struct ContentView: View {
    let weatherProvider: any WeatherProviding

    var body: some View {
        WeatherScreen(weatherProvider: weatherProvider)
    }
}

#Preview {
    ContentView(weatherProvider: MockWeatherProvider())
}

