import Foundation

nonisolated enum WeatherUnitPreference: String, Codable, Sendable {
    case metric
}

nonisolated enum WeatherConditionCode: Int, Codable, Sendable {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowFallSlight = 71
    case snowFallModerate = 73
    case snowFallHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstorm = 95
    case thunderstormSlightHail = 96
    case thunderstormHeavyHail = 99

    var localizedText: String {
        switch self {
        case .clearSky: return "晴"
        case .mainlyClear: return "基本晴朗"
        case .partlyCloudy: return "多云"
        case .overcast: return "阴"
        case .fog, .depositingRimeFog: return "雾"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "毛毛雨"
        case .freezingDrizzleLight, .freezingDrizzleDense: return "冻毛毛雨"
        case .rainSlight, .rainModerate, .rainHeavy: return "雨"
        case .freezingRainLight, .freezingRainHeavy: return "冻雨"
        case .snowFallSlight, .snowFallModerate, .snowFallHeavy: return "雪"
        case .snowGrains: return "雪粒"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent: return "阵雨"
        case .snowShowersSlight, .snowShowersHeavy: return "阵雪"
        case .thunderstorm: return "雷暴"
        case .thunderstormSlightHail, .thunderstormHeavyHail: return "强雷暴"
        }
    }
}

nonisolated struct CurrentWeather: Codable, Sendable {
    var observationTime: Date
    var condition: WeatherConditionCode
    var isDay: Bool
    var temperature: Measurement<UnitTemperature>
    var apparentTemperature: Measurement<UnitTemperature>?
    var humidity: Double?
    var windSpeed: Measurement<UnitSpeed>
    var windDirectionDegrees: Double
    var windGust: Measurement<UnitSpeed>?
    var pressure: Measurement<UnitPressure>?
    var visibility: Measurement<UnitLength>?
    var precipitation: Measurement<UnitLength>?
}

nonisolated struct HourlyPoint: Codable, Sendable, Identifiable {
    var id: Date { time }
    var time: Date
    var temperature: Measurement<UnitTemperature>
    var precipitationProbability: Int?
    var condition: WeatherConditionCode?
}

nonisolated struct DailyPoint: Codable, Sendable, Identifiable {
    var id: Date { date }
    var date: Date
    var minTemperature: Measurement<UnitTemperature>
    var maxTemperature: Measurement<UnitTemperature>
    var condition: WeatherConditionCode?
    var sunrise: Date?
    var sunset: Date?
    var uvIndexMax: Double?
    var precipitationTotal: Measurement<UnitLength>?
}

nonisolated struct WeatherSnapshot: Codable, Sendable {
    var place: Place
    var timezoneIdentifier: String
    var fetchedAt: Date
    var validUntil: Date
    var current: CurrentWeather
    var hourly: [HourlyPoint]
    var daily: [DailyPoint]

    var isExpired: Bool {
        Date() > validUntil
    }
}
