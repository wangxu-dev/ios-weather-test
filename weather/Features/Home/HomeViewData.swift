import Foundation

struct HomeWeatherViewData {
    struct DailyItem: Identifiable {
        let id: Date
        let label: String
        let conditionText: String
        let minText: String
        let maxText: String
    }

    struct HourlyItem: Identifiable {
        let id: Date
        let time: String
        let temperatureText: String
        let popText: String
    }

    let title: String
    let subtitle: String
    let currentTemperature: String
    let highLowText: String
    let feelsLikeText: String
    let humidityText: String
    let windText: String
    let precipitationText: String
    let updateTimeText: String
    let symbolName: String
    let hourly: [HourlyItem]
    let daily: [DailyItem]
    let isStale: Bool
}

enum HomeWeatherViewDataMapper {
    static func map(snapshot: WeatherSnapshot, isStale: Bool) -> HomeWeatherViewData {
        let formatting = WeatherFormatting(timezone: TimeZone(identifier: snapshot.timezoneIdentifier) ?? .current)
        let current = snapshot.current

        let hourly = snapshot.hourly.prefix(24).map {
            HomeWeatherViewData.HourlyItem(
                id: $0.time,
                time: formatting.timeText($0.time),
                temperatureText: formatting.temperatureText($0.temperature),
                popText: $0.precipitationProbability.map { "\($0)%" } ?? "—"
            )
        }

        let daily = snapshot.daily.prefix(7).enumerated().map { index, item in
            HomeWeatherViewData.DailyItem(
                id: item.date,
                label: formatting.dayText(item.date, index: index),
                conditionText: (item.condition ?? current.condition).localizedText,
                minText: formatting.temperatureText(item.minTemperature),
                maxText: formatting.temperatureText(item.maxTemperature)
            )
        }

        let fallbackHigh = formatting.temperatureText(current.temperature)
        let fallbackLow = formatting.temperatureText(current.temperature)
        let highText = daily.first?.maxText ?? fallbackHigh
        let lowText = daily.first?.minText ?? fallbackLow

        return HomeWeatherViewData(
            title: snapshot.place.displayName,
            subtitle: current.condition.localizedText,
            currentTemperature: formatting.temperatureText(current.temperature),
            highLowText: "最高 \(highText) / 最低 \(lowText)",
            feelsLikeText: current.apparentTemperature.map { "体感 \(formatting.temperatureText($0))" } ?? "体感 —",
            humidityText: formatting.humidityText(current.humidity),
            windText: "\(formatting.windDirectionText(degrees: current.windDirectionDegrees)) · \(formatting.speedText(current.windSpeed))",
            precipitationText: formatting.precipitationText(current.precipitation),
            updateTimeText: formatting.timeText(current.observationTime),
            symbolName: symbolName(condition: current.condition, isDay: current.isDay),
            hourly: hourly,
            daily: daily,
            isStale: isStale
        )
    }

    static func symbolName(condition: WeatherConditionCode, isDay: Bool) -> String {
        switch condition {
        case .clearSky:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case .mainlyClear, .partlyCloudy:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .overcast:
            return "cloud.fill"
        case .fog, .depositingRimeFog:
            return "cloud.fog.fill"
        case .drizzleLight, .drizzleModerate, .drizzleDense, .freezingDrizzleLight, .freezingDrizzleDense:
            return "cloud.drizzle.fill"
        case .rainSlight, .rainModerate, .rainHeavy, .freezingRainLight, .freezingRainHeavy, .rainShowersSlight, .rainShowersModerate, .rainShowersViolent:
            return "cloud.rain.fill"
        case .snowFallSlight, .snowFallModerate, .snowFallHeavy, .snowGrains, .snowShowersSlight, .snowShowersHeavy:
            return "cloud.snow.fill"
        case .thunderstorm, .thunderstormSlightHail, .thunderstormHeavyHail:
            return "cloud.bolt.rain.fill"
        }
    }
}
