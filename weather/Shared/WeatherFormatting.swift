import Foundation

struct WeatherFormatting {
    private let locale: Locale
    private let timezone: TimeZone

    init(locale: Locale = .current, timezone: TimeZone = .current) {
        self.locale = locale
        self.timezone = timezone
    }

    func temperatureText(_ value: Measurement<UnitTemperature>) -> String {
        "\(Int(value.converted(to: .celsius).value.rounded()))°"
    }

    func speedText(_ value: Measurement<UnitSpeed>) -> String {
        let v = value.converted(to: .metersPerSecond).value
        if v < 10 {
            return "\(v.formatted(.number.precision(.fractionLength(1)))) m/s"
        }
        return "\(Int(v.rounded())) m/s"
    }

    func humidityText(_ humidity: Double?) -> String {
        guard let humidity else { return "—" }
        return "\(Int(humidity.rounded()))%"
    }

    func precipitationText(_ value: Measurement<UnitLength>?) -> String {
        guard let value else { return "—" }
        let mm = value.converted(to: .millimeters).value
        if mm < 1 {
            return "\(mm.formatted(.number.precision(.fractionLength(1)))) mm"
        }
        return "\(Int(mm.rounded())) mm"
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timezone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func dayText(_ date: Date, index: Int) -> String {
        if index == 0 { return "今天" }
        if index == 1 { return "明天" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timezone
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }

    func windDirectionText(degrees: Double) -> String {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let idx = Int((normalized / 22.5).rounded()) % 16
        let values = ["北风", "北东北风", "东北风", "东东北风", "东风", "东东南风", "东南风", "南东南风", "南风", "南西南风", "西南风", "西西南风", "西风", "西西北风", "西北风", "北西北风"]
        return values[idx]
    }
}
