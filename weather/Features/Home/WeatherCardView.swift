//
//  WeatherCardView.swift
//  weather
//

import SwiftUI

struct WeatherCardView: View {
    let city: String
    let state: HomeViewModel.WeatherState
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            bodyContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
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
                weatherBody(info)
            } else {
                notice(systemImage: "questionmark", title: city, message: "未获取到天气数据。")
            }

            if !payload.alarms.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("预警")
                        .font(.headline)

                    ForEach(payload.alarms) { alarm in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(alarm.title)
                                .fontWeight(.semibold)

                            Text(alarm.type)
                                .foregroundStyle(.secondary)

                            Text(alarm.publishTime)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Text(alarm.details)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)

                        if alarm.id != payload.alarms.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func weatherBody(_ info: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: symbolName(for: info.weather))
                    .font(.system(size: 48, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.weather)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("\(info.tempHigh)°")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("最低 \(info.tempLow)°")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack(spacing: 12) {
                Label("\(info.windDirection) \(info.windScale)", systemImage: "wind")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            HStack(spacing: 16) {
                metricPair(title: "最低", value: "\(info.tempLow)°")
                metricPair(title: "最高", value: "\(info.tempHigh)°")
            }
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

    private func metricPair(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    private func symbolName(for weatherText: String) -> String {
        if weatherText.contains("晴") { return "sun.max.fill" }
        if weatherText.contains("云") || weatherText.contains("阴") { return "cloud.fill" }
        if weatherText.contains("雨") { return "cloud.rain.fill" }
        if weatherText.contains("雪") { return "cloud.snow.fill" }
        if weatherText.contains("雾") { return "cloud.fog.fill" }
        if weatherText.contains("沙") { return "sun.dust.fill" }
        return "cloud.sun.fill"
    }
}
