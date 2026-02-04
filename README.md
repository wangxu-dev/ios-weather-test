# Weather (iOS 26 Learning Project)

This repository is a small **practice project** for learning **Swift / SwiftUI** by building a simple Weather app.

## Goals

- Learn SwiftUI app structure and state management
- Build a clean, decoupled “WeatherCore” module (data + domain)
- Experiment with a modern iOS 26-style UI (glass / light & dark mode)
- Keep the codebase readable and beginner-friendly

## What It Does (So Far)

- Search cities and query weather data
- Maintain an “added cities” list
- Swipe-to-delete for added cities
- Basic caching so the app can render quickly on launch, then refresh silently
- Optional “location recommendation” (IP-based) to suggest a city in the search list

## Project Structure

- `weather/WeatherCore`
  - Domain models and protocols (Weather provider, city suggester, caching, etc.)
  - Data implementations (network clients, UserDefaults stores)
- `weather/Features`
  - `Home`: main UI (added cities + weather display)
  - `Weather`: earlier single-screen prototype and shared views
  - `AddCity`: auxiliary UI for adding cities (may evolve)
- `weather.xcodeproj`: Xcode project

## Requirements

- Xcode 26 (or newer)
- iOS 26 Simulator / device

## Running

1. Open `weather.xcodeproj` in Xcode
2. Select a simulator (iOS 26) or a device
3. Run the `weather` target

## Notes

- This is a learning project; the architecture and UI are expected to evolve.
- Networking APIs and data sources may be swapped later (the code is designed to keep modules decoupled).

## License

For personal learning and experimentation.

