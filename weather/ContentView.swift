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
        HomeScreen(
            weatherProvider: weatherProvider,
            cityStore: UserDefaultsCityListStore.shared
        )
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(weatherProvider: MockWeatherProvider())
    }
}
#endif
