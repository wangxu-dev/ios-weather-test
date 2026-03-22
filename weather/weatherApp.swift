import SwiftUI

@MainActor
@main
struct WeatherApp: App {
    @State private var environment = WeatherAppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
        }
    }
}
