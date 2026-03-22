import SwiftUI

struct ContentView: View {
    let environment: WeatherAppEnvironment

    var body: some View {
        HomeScreen(viewModel: environment.homeViewModel)
    }
}
