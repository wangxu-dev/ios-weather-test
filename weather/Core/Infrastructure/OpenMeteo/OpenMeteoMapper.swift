import Foundation

nonisolated enum OpenMeteoMapper {
    static func mapForecast(place: Place, response: OpenMeteoForecastResponse) throws -> WeatherSnapshot {
        let timezone = TimeZone(identifier: response.timezone) ?? .current

        let isoWithZone = ISO8601DateFormatter()
        isoWithZone.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let plainDateTime = DateFormatter()
        plainDateTime.locale = Locale(identifier: "en_US_POSIX")
        plainDateTime.timeZone = timezone
        plainDateTime.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let plainDateTimeWithSeconds = DateFormatter()
        plainDateTimeWithSeconds.locale = Locale(identifier: "en_US_POSIX")
        plainDateTimeWithSeconds.timeZone = timezone
        plainDateTimeWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let plainDate = DateFormatter()
        plainDate.locale = Locale(identifier: "en_US_POSIX")
        plainDate.timeZone = timezone
        plainDate.dateFormat = "yyyy-MM-dd"

        func parseDate(_ value: String) throws -> Date {
            let normalized = value.replacingOccurrences(of: " ", with: "T")
            if let date = isoWithZone.date(from: normalized)
                ?? plainDateTimeWithSeconds.date(from: normalized)
                ?? plainDateTime.date(from: normalized)
                ?? plainDate.date(from: normalized)
            {
                return date
            }
            throw AppError.decoding("时间解析失败：\(value)")
        }

        guard let condition = WeatherConditionCode(rawValue: response.current.weatherCode) else {
            throw AppError.decoding("不支持的天气码：\(response.current.weatherCode)")
        }

        let currentDate = try parseDate(response.current.time)
        let current = CurrentWeather(
            observationTime: currentDate,
            condition: condition,
            isDay: (response.current.isDay ?? 1) == 1,
            temperature: Measurement(value: response.current.temperature2m, unit: .celsius),
            apparentTemperature: response.current.apparentTemperature.map { Measurement(value: $0, unit: UnitTemperature.celsius) },
            humidity: response.current.relativeHumidity2m,
            windSpeed: Measurement(value: response.current.windSpeed10m, unit: .metersPerSecond),
            windDirectionDegrees: response.current.windDirection10m,
            windGust: response.current.windGusts10m.map { Measurement(value: $0, unit: UnitSpeed.metersPerSecond) },
            pressure: response.current.pressureMsl.map { Measurement(value: $0, unit: UnitPressure.hectopascals) },
            visibility: response.current.visibility.map { Measurement(value: $0, unit: UnitLength.meters) },
            precipitation: response.current.precipitation.map { Measurement(value: $0, unit: UnitLength.millimeters) }
        )

        let hourlyCount = min(response.hourly.time.count, response.hourly.temperature2m.count)
        let hourly: [HourlyPoint] = (0..<hourlyCount).compactMap { idx -> HourlyPoint? in
            guard let time = try? parseDate(response.hourly.time[idx]) else { return nil }
            let conditionCode: WeatherConditionCode? = {
                guard let codes = response.hourly.weatherCode, codes.indices.contains(idx) else { return nil }
                return WeatherConditionCode(rawValue: codes[idx])
            }()
            let pop: Int? = {
                guard let values = response.hourly.precipitationProbability, values.indices.contains(idx) else { return nil }
                return values[idx]
            }()
            return HourlyPoint(
                time: time,
                temperature: Measurement(value: response.hourly.temperature2m[idx], unit: .celsius),
                precipitationProbability: pop,
                condition: conditionCode
            )
        }

        let dailyCount = min(response.daily.time.count, response.daily.temperature2mMax.count, response.daily.temperature2mMin.count)
        let daily: [DailyPoint] = (0..<dailyCount).compactMap { idx -> DailyPoint? in
            guard let date = try? parseDate(response.daily.time[idx]) else { return nil }
            let conditionCode: WeatherConditionCode? = {
                guard let codes = response.daily.weatherCode, codes.indices.contains(idx) else { return nil }
                return WeatherConditionCode(rawValue: codes[idx])
            }()
            let sunrise: Date? = {
                guard let values = response.daily.sunrise, values.indices.contains(idx) else { return nil }
                return try? parseDate(values[idx])
            }()
            let sunset: Date? = {
                guard let values = response.daily.sunset, values.indices.contains(idx) else { return nil }
                return try? parseDate(values[idx])
            }()
            let precipitation: Measurement<UnitLength>? = {
                guard let values = response.daily.precipitationSum, values.indices.contains(idx) else { return nil }
                return Measurement(value: values[idx], unit: UnitLength.millimeters)
            }()
            return DailyPoint(
                date: date,
                minTemperature: Measurement(value: response.daily.temperature2mMin[idx], unit: .celsius),
                maxTemperature: Measurement(value: response.daily.temperature2mMax[idx], unit: .celsius),
                condition: conditionCode,
                sunrise: sunrise,
                sunset: sunset,
                uvIndexMax: response.daily.uvIndexMax?.indices.contains(idx) == true ? response.daily.uvIndexMax?[idx] : nil,
                precipitationTotal: precipitation
            )
        }

        return WeatherSnapshot(
            place: place,
            timezoneIdentifier: response.timezone,
            fetchedAt: Date(),
            validUntil: Date().addingTimeInterval(15 * 60),
            current: current,
            hourly: hourly,
            daily: daily
        )
    }

    static func mapPlace(_ result: OpenMeteoGeocodingResponse.Result, isCurrentLocation: Bool = false) -> Place {
        Place(
            name: result.name,
            admin: result.admin1,
            country: result.country,
            coordinate: Coordinate(latitude: result.latitude, longitude: result.longitude),
            isCurrentLocation: isCurrentLocation
        )
    }
}
