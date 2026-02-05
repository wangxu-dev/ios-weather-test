//
//  WeatherCardView.swift
//  weather
//

import SwiftUI
import Foundation

struct WeatherCardView: View {
    let place: Place
    let state: HomeViewModel.WeatherState
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            bodyContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 0)
        .padding(.bottom, 24)
    }

    private var isLoading: Bool {
        switch state {
        case .loading:
            return true
        case .idle, .failed, .loaded:
            return false
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        switch state {
        case .idle:
            notice(systemImage: "cloud", title: "准备就绪", message: "进入前台后会自动更新天气。")

        case .loading:
            notice(systemImage: "hourglass", title: "加载中…", message: "正在获取天气数据。")

        case .failed(let message):
            notice(systemImage: "exclamationmark.triangle.fill", title: "请求失败", message: message)

        case .loaded(let payload):
            if let info = payload.weatherInfo {
                weatherBody(info, payload: payload)
            } else {
                notice(systemImage: "questionmark", title: place.displayName, message: "未获取到天气数据。")
            }
        }
    }

    private func weatherBody(_ info: WeatherInfo, payload: WeatherPayload) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            hero(info)

            highlights(info, payload: payload)

            if let hourly = payload.hourly {
                WeatherSection("24 小时") {
                    VStack(alignment: .leading, spacing: 10) {
                        HourlyChart(
                            times: hourly.time,
                            temperatures: hourly.temperature2m,
                            pops: hourly.precipitationProbability
                        )
                        HStack {
                            Text("温度")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("降水概率")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)

                        HourlyTicks(hourly: hourly, symbolName: symbolName(weatherCode:isDay:))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                    }
                    .padding(.top, 12)
                }
            }

            if let daily = payload.daily {
                WeatherSection("未来 7 天") {
                    VStack(spacing: 0) {
                        let rows = makeDailyItems(daily, maxCount: 7)
                        let globalMin = rows.map(\.min).min() ?? 0
                        let globalMax = rows.map(\.max).max() ?? 1

                        ForEach(rows.indices, id: \.self) { idx in
                            let row = rows[idx]
                            HStack(spacing: 12) {
                                Text(row.label)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 54, alignment: .leading)

                                Image(systemName: symbolName(weatherCode: row.weatherCode, isDay: true))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22)

                                TemperatureRangeBar(
                                    min: Double(globalMin),
                                    max: Double(globalMax),
                                    value: Double((row.min + row.max) / 2)
                                )

                                Text("\(row.min)°/\(row.max)°")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(.primary)
                                    .frame(width: 76, alignment: .trailing)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                            if idx != rows.indices.last {
                                Divider().opacity(0.45)
                            }
                        }
                    }
                }
            }
        }
    }

    private func hero(_ info: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: symbolName(weatherCode: info.weatherCode, isDay: info.isDay))
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.weather)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(info.tempCurrent ?? info.tempHigh)°")
                            .font(.system(size: 62, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("最高 \(info.tempHigh)°")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text("最低 \(info.tempLow)°")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()

                            Label(compactUpdateTime(info.updateTime), systemImage: "clock")
                                .labelStyle(.titleAndIcon)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(alignment: .topLeading) {
            HeroGlow(weatherCode: info.weatherCode, isDay: info.isDay)
                .padding(.top, 4)
                .padding(.leading, 4)
        }
    }

    private func notice(systemImage: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func highlights(_ info: WeatherInfo, payload: WeatherPayload) -> some View {
        WeatherSection("关键指标") {
            VStack(alignment: .leading, spacing: 12) {
                let popNow = payload.hourly?.precipitationProbability?.first
                let precipNow = info.precipitationMm
                let windValue = info.windScale
                let windDetail = [
                    info.windDirection,
                    info.windGustMetersPerSecond.map { "阵风 \(String(format: "%.1f", $0))" } ?? info.windGust,
                ]
                .compactMap { $0 }
                .joined(separator: "\n")

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        WeatherHighlightTile(
                            title: "风",
                            value: windValue,
                            subtitle: windDetail,
                            accent: Color.primary.opacity(0.92)
                        ) {
                            WindCompass(degrees: info.windDegrees, speed: info.windSpeedMetersPerSecond)
                                .frame(width: 44, height: 44)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider().opacity(0.28)

                        WeatherHighlightTile(
                            title: "湿度",
                            value: info.humidity ?? "—",
                            subtitle: info.feelsLike.map { "体感 \($0)°" },
                            accent: Color(red: 0.50, green: 0.90, blue: 1.00)
                        ) {
                            RingGauge(
                                progress: normalizedHumidity(info.humidityPercent) ?? 0,
                                tint: Color(red: 0.50, green: 0.90, blue: 1.00)
                            )
                            .frame(width: 44, height: 44)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider().opacity(0.28)

                    HStack(spacing: 0) {
                        WeatherHighlightTile(
                            title: "紫外线",
                            value: info.uvIndexMax.map { "UV \($0)" } ?? "—",
                            subtitle: uvLevelText(info.uvIndexMaxValue),
                            accent: Color(red: 1.00, green: 0.90, blue: 0.55)
                        ) {
                            UVGauge(progress: normalizedUV(info.uvIndexMaxValue) ?? 0)
                                .frame(width: 44, height: 44)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider().opacity(0.28)

                        WeatherHighlightTile(
                            title: "降水",
                            value: info.precipitation ?? "—",
                            subtitle: popNow.map { "降水概率 \($0)%" } ?? (precipNow.map { $0 == 0 ? "当前无降水" : "当前强度" }),
                            accent: Color(red: 0.50, green: 0.90, blue: 1.00)
                        ) {
                            PrecipGauge(
                                progress: normalizedPrecip(precipNow) ?? 0,
                                tint: Color(red: 0.50, green: 0.90, blue: 1.00)
                            )
                            .frame(width: 44, height: 44)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if info.sunrise != nil || info.sunset != nil {
                        Divider().opacity(0.28)
                        SunPathTile(
                            updateTime: info.updateTime,
                            sunrise: info.sunrise,
                            sunset: info.sunset
                        )
                    }
                }

                if info.pressure != nil || info.visibility != nil || info.windGust != nil {
                    let pressureText = info.pressure.map { "气压 \($0)" }
                    let visibilityText = info.visibility.map { "能见度 \($0)" }
                    let gustText = info.windGust.map { "阵风 \($0)" }
                    let items = [pressureText, visibilityText, gustText].compactMap { $0 }
                    if !items.isEmpty {
                        Text(items.joined(separator: " · "))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                    }
                }

            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    private func compactUpdateTime(_ raw: String) -> String {
        // Prefer showing time only to avoid truncation.
        // Accept "YYYY-MM-DD HH:mm" / "YYYY-MM-DD HH:mm:ss" / "HH:mm"
        let value = raw.replacingOccurrences(of: "T", with: " ")
        if value.count >= 16 {
            let start = value.index(value.startIndex, offsetBy: 11)
            let end = value.index(value.startIndex, offsetBy: 16)
            return String(value[start..<end])
        }
        if value.count >= 5, value.contains(":") {
            return String(value.suffix(5))
        }
        return value
    }

    private func symbolName(weatherCode: Int?, isDay: Bool?) -> String {
        let day = isDay ?? true
        let code = weatherCode ?? -1
        switch code {
        case 0:
            return day ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:
            return day ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67:
            return "cloud.rain.fill"
        case 71, 73, 75, 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return day ? "cloud.sun.fill" : "cloud.moon.fill"
        }
    }

    private func normalizedWind(_ speed: Double?) -> Double? {
        guard let speed else { return nil }
        // 0–20 m/s -> 0–1
        return min(1, max(0, speed / 20.0))
    }

    private func normalizedHumidity(_ percent: Int?) -> Double? {
        guard let percent else { return nil }
        return min(1, max(0, Double(percent) / 100.0))
    }

    private func normalizedPrecip(_ mm: Double?) -> Double? {
        guard let mm else { return nil }
        // 0–10 mm -> 0–1 (current intensity is usually small)
        return min(1, max(0, mm / 10.0))
    }

    private func normalizedUV(_ uv: Double?) -> Double? {
        guard let uv else { return nil }
        // 0–11+ scale
        return min(1, max(0, uv / 11.0))
    }

    private func uvLevelText(_ uv: Double?) -> String? {
        guard let uv else { return nil }
        switch uv {
        case ..<3:
            return "低"
        case ..<6:
            return "中"
        case ..<8:
            return "高"
        case ..<11:
            return "很高"
        default:
            return "极高"
        }
    }

    private func sunriseSunsetText(_ info: WeatherInfo) -> String? {
        let sunrise = info.sunrise
        let sunset = info.sunset
        if sunrise == nil, sunset == nil { return nil }
        if let sunrise, let sunset {
            return "日出 \(sunrise) · 日落 \(sunset)"
        }
        if let sunrise { return "日出 \(sunrise)" }
        if let sunset { return "日落 \(sunset)" }
        return nil
    }

    private struct HourlyItem {
        let time: String
        let label: String
        let temp: Int
        let pop: Int?
        let weatherCode: Int?
    }

    private func makeHourlyItems(_ hourly: HourlyForecast, maxCount: Int) -> [HourlyItem] {
        let count = min(maxCount, hourly.time.count, hourly.temperature2m.count)
        guard count > 0 else { return [] }

        return (0..<count).map { idx in
            HourlyItem(
                time: hourly.time[idx],
                label: hourLabel(hourly.time[idx]),
                temp: Int(hourly.temperature2m[idx].rounded()),
                pop: hourly.precipitationProbability?.indices.contains(idx) == true ? hourly.precipitationProbability?[idx] : nil,
                weatherCode: hourly.weatherCode?.indices.contains(idx) == true ? hourly.weatherCode?[idx] : nil
            )
        }
    }

    private struct DailyItem {
        let label: String
        let min: Int
        let max: Int
        let weatherCode: Int?
    }

    private func makeDailyItems(_ daily: DailyForecast, maxCount: Int) -> [DailyItem] {
        let maxs = daily.temperature2mMax ?? []
        let mins = daily.temperature2mMin ?? []
        let count = min(maxCount, daily.time.count, maxs.count, mins.count)
        guard count > 0 else { return [] }

        return (0..<count).map { idx in
            DailyItem(
                label: dayLabel(daily.time[idx], index: idx),
                min: Int(mins[idx].rounded()),
                max: Int(maxs[idx].rounded()),
                weatherCode: daily.weatherCode?.indices.contains(idx) == true ? daily.weatherCode?[idx] : nil
            )
        }
    }

    private func hourLabel(_ iso: String) -> String {
        // "YYYY-MM-DDTHH:mm" or "YYYY-MM-DD HH:mm"
        let value = iso.replacingOccurrences(of: "T", with: " ")
        guard value.count >= 16 else { return value }
        let start = value.index(value.startIndex, offsetBy: 11)
        let end = value.index(value.startIndex, offsetBy: 16)
        return String(value[start..<end])
    }

    private func dayLabel(_ isoDate: String, index: Int) -> String {
        if index == 0 { return "今天" }
        if index == 1 { return "明天" }
        // fallback: MM-DD
        let value = isoDate.replacingOccurrences(of: "T", with: " ")
        guard value.count >= 10 else { return value }
        let start = value.index(value.startIndex, offsetBy: 5)
        let end = value.index(value.startIndex, offsetBy: 10)
        return String(value[start..<end])
    }
}
