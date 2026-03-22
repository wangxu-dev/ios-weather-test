import Foundation

nonisolated struct OpenMeteoGeocodingResponse: Decodable, Sendable {
    nonisolated struct Result: Decodable, Sendable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }

    let results: [Result]?
}

nonisolated struct OpenMeteoForecastResponse: Decodable, Sendable {
    nonisolated struct Current: Decodable, Sendable {
        let time: String
        let temperature2m: Double
        let relativeHumidity2m: Double?
        let apparentTemperature: Double?
        let precipitation: Double?
        let weatherCode: Int
        let pressureMsl: Double?
        let visibility: Double?
        let windGusts10m: Double?
        let isDay: Int?
        let windSpeed10m: Double
        let windDirection10m: Double

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case precipitation
            case weatherCode = "weather_code"
            case pressureMsl = "pressure_msl"
            case visibility
            case windGusts10m = "wind_gusts_10m"
            case isDay = "is_day"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
        }
    }

    nonisolated struct Hourly: Decodable, Sendable {
        let time: [String]
        let temperature2m: [Double]
        let precipitationProbability: [Int]?
        let weatherCode: [Int]?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
            case weatherCode = "weather_code"
        }
    }

    nonisolated struct Daily: Decodable, Sendable {
        let time: [String]
        let weatherCode: [Int]?
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let sunrise: [String]?
        let sunset: [String]?
        let uvIndexMax: [Double]?
        let precipitationSum: [Double]?

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case sunrise
            case sunset
            case uvIndexMax = "uv_index_max"
            case precipitationSum = "precipitation_sum"
        }
    }

    let timezone: String
    let current: Current
    let hourly: Hourly
    let daily: Daily
}
