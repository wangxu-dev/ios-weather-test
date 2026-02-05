//
//  WeatherCardView.swift
//  weather
//

import SwiftUI

struct WeatherCardView: View {
    let place: Place
    let state: HomeViewModel.WeatherState
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            bodyContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
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

            metaRow(info)

            if let metrics = metrics(info), !metrics.isEmpty {
                metricsGrid(metrics)
            }

            if let hourly = payload.hourly {
                hourlyPreview(hourly)
            }

            if let daily = payload.daily {
                dailyPreview(daily)
            }
        }
    }

    private func hero(_ info: WeatherInfo) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbolName(weatherCode: info.weatherCode, isDay: info.isDay))
                .font(.system(size: 50, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 3) {
                Text(info.weather)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(info.tempCurrent ?? info.tempHigh)°")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("最低 \(info.tempLow)°  最高 \(info.tempHigh)°")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
    }

    private func metaRow(_ info: WeatherInfo) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                GlassPill(systemImage: "wind", text: "\(info.windDirection) \(info.windScale)")
                GlassPill(systemImage: "clock", text: info.updateTime)
                if let sunrise = info.sunrise {
                    GlassPill(systemImage: "sunrise.fill", text: sunrise)
                }
                if let sunset = info.sunset {
                    GlassPill(systemImage: "sunset.fill", text: sunset)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func metrics(_ info: WeatherInfo) -> [(title: String, value: String)]? {
        var items: [(String, String)] = []

        if let feelsLike = info.feelsLike { items.append(("体感", "\(feelsLike)°")) }
        if let humidity = info.humidity { items.append(("湿度", humidity)) }
        if let precipitation = info.precipitation { items.append(("降水", precipitation)) }
        if let pressure = info.pressure { items.append(("气压", pressure)) }
        if let visibility = info.visibility { items.append(("能见度", visibility)) }
        if let windGust = info.windGust { items.append(("阵风", windGust)) }
        if let uvIndexMax = info.uvIndexMax { items.append(("UV", uvIndexMax)) }

        return items
    }

    private func metricsGrid(_ metrics: [(title: String, value: String)]) -> some View {
        let columns = [
            GridItem(.flexible(minimum: 120), spacing: 10),
            GridItem(.flexible(minimum: 120), spacing: 10),
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(metrics, id: \.title) { item in
                MetricChip(title: item.title, value: item.value)
            }
        }
        .padding(.top, 4)
    }

    private func hourlyPreview(_ hourly: HourlyForecast) -> some View {
        let items = makeHourlyItems(hourly, maxCount: 14)
        guard !items.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("24 小时")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items, id: \.time) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 8) {
                                    Image(systemName: symbolName(weatherCode: item.weatherCode, isDay: true))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)

                                    Text("\(item.temp)°")
                                        .font(.headline.weight(.semibold))
                                        .monospacedDigit()
                                }

                                if let pop = item.pop {
                                    Text("降水 \(pop)%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .weatherGlassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.top, 6)
        )
    }

    private func dailyPreview(_ daily: DailyForecast) -> some View {
        let rows = makeDailyItems(daily, maxCount: 7)
        guard !rows.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("未来 7 天")
                    .font(.headline)

                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { idx in
                        let row = rows[idx]
                        HStack(spacing: 12) {
                            Text(row.label)
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 52, alignment: .leading)

                            Image(systemName: symbolName(weatherCode: row.weatherCode, isDay: true))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)

                            Spacer(minLength: 0)

                            Text("\(row.min)° / \(row.max)°")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        if idx != rows.indices.last {
                            Divider()
                                .opacity(0.55)
                        }
                    }
                }
                .weatherGlassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 6)
        )
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
