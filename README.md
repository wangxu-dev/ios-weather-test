# Weather (iOS 26 Apple-style Refactor)

A fully refactored SwiftUI weather app oriented around iOS 26 design patterns and long-term maintainability.

## Refactor Goals

- Use modern SwiftUI + Observation + Swift Concurrency patterns.
- Rebuild models with strong domain semantics (no UI-formatted string fields in domain).
- Separate responsibilities into App / Domain / Application / Infrastructure / Features layers.
- Provide iOS 26 glass-forward UI with lower iOS fallback behavior.
- Reserve a clean AI extension interface without coupling business logic to LLM providers.

## Architecture

- `weather/App`
  - Composition root and dependency wiring.
- `weather/Core/Domain`
  - Strong domain entities and repository protocols.
- `weather/Core/Application`
  - Use-case orchestration and state semantics.
- `weather/Core/Infrastructure`
  - Open-Meteo API, location provider, UserDefaults actor stores, migration logic.
- `weather/Features/Home`
  - Main weather screen, view model, and display mapping.
- `weather/Features/Search`
  - Search overlay component.
- `weather/Features/DesignSystem`
  - Design tokens and glass compatibility layer.
- `weather/Features/AI`
  - AI protocol boundary and noop implementation.
- `weather/Shared`
  - AppError and formatting helpers.

## Key Decisions

- Big-bang replacement: old `Features/Weather`, `Features/AddCity`, and `WeatherCore` were removed.
- Repository + persistence boundaries are protocol-driven and `Sendable`.
- Storage moved to actor-backed implementations for safer concurrent access.
- Cache snapshots include validity windows; stale cache is rendered as stale instead of blanking UI.
- AI integration is interface-only in this phase (`NoopAIProvider`).

## Data Source

- Weather and geocoding: Open-Meteo.

## iOS UI Direction

- Unified glass containers and cards with tokenized spacing/radius/type hierarchy.
- Search flow is separated from content flow and state-driven.
- Home content hierarchy:
  1. City header
  2. Current weather hero
  3. Key metrics
  4. 24-hour trend
  5. 7-day trend

## Migration

`UserDefaults` migration keys upgraded to v3.

- `places.v3`
- `selected.place.id.v3`
- `weather.cache.v3`

Migration attempts to read legacy keys and transform compatible data into new domain snapshots.

## Next Phase (Planned)

- Add dedicated test target and implement unit/concurrency/UI tests from `docs/REFACTOR_SPEC.md`.
- Introduce typed feature flags and telemetry hooks.
- Plug a real AI provider behind `AIWeatherAssistantProviding`.

