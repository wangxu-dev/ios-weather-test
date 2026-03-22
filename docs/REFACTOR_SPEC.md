# Refactor Spec and Quality Checklist

## Scope Delivered

- Completed layered architecture rewrite.
- Removed legacy Weather/AddCity paths.
- Replaced weak weather string models with typed domain snapshots.
- Added actor-based stores and migration path.
- Added iOS 26 style design tokens and glass wrappers.
- Added AI boundary protocol and noop provider.

## Public Interfaces

- `WeatherRepository.fetchWeather(for:)`
- `PlaceRepository.search(query:limit:)`
- `PlaceRepository.resolveCurrentLocation()`
- `AIWeatherAssistantProviding.summarize(snapshot:context:)`
- `AIWeatherAssistantProviding.suggestActions(snapshot:context:)`

## Non-functional Quality Rules

- No `AnyView`-based view branching.
- No `ForEach(indices)` for dynamic lists.
- View body remains declarative and side-effect free.
- Task lifecycle controlled in view model/use case boundaries.
- Persistence through protocols only.

## Test Matrix (to implement in test target)

1. DTO to domain mapping
- Valid response decoding.
- Missing optional fields.
- Unsupported weather code handling.

2. Migration and cache
- Legacy place payload migration.
- Legacy weather cache migration.
- Cache stale flag behavior.

3. Concurrency
- Concurrent place save/load consistency.
- Refresh cancellation when switching city rapidly.

4. UI behavior
- Search state transitions: idle/searching/results/empty/error.
- Stale cache presentation.
- Current-location add and fallback handling.

## Acceptance Criteria

- App uses new layered structure exclusively.
- No references to old WeatherCore/Weather/AddCity modules.
- Home/search flows are state-driven.
- AI remains optional and decoupled.

