//
//  WeatherCardView.swift
//  weather
//

import SwiftUI

struct WeatherCardView: View {
    let city: String
    let state: HomeViewModel.WeatherState
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            switch state {
            case .idle:
                GlassNotice(systemImage: "cloud", title: city, message: "点击刷新获取天气。")

            case .loading:
                GlassNotice(systemImage: "hourglass", title: city, message: "加载中…")

            case .failed(let message):
                GlassNotice(systemImage: "exclamationmark.triangle.fill", title: "请求失败", message: message)

            case .loaded(let payload):
                if let info = payload.weatherInfo {
                    weatherBody(info)
                } else {
                    GlassNotice(systemImage: "questionmark", title: city, message: "未获取到天气数据。")
                }

                if !payload.alarms.isEmpty {
                    Divider()
                    DisclosureGroup("预警") {
                        VStack(spacing: 10) {
                            ForEach(payload.alarms) { alarm in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(alarm.title)
                                        .fontWeight(.semibold)
                                    Text(alarm.type)
                                        .foregroundStyle(.secondary)
                                    Text(alarm.publishTime)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .glassEffect(in: .rect(cornerRadius: 16))
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 8)
    }

    private var header: some View {
        HStack {
            Text(city)
                .font(.title3.weight(.semibold))

            Spacer(minLength: 0)

            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("刷新")
        }
    }

    private func weatherBody(_ info: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack(spacing: 10) {
                GlassPill(systemImage: "wind", text: "\(info.windDirection) \(info.windScale)")
                GlassPill(systemImage: "clock", text: info.updateTime)
            }

            HStack(spacing: 10) {
                MetricChip(title: "最低", value: "\(info.tempLow)°")
                MetricChip(title: "最高", value: "\(info.tempHigh)°")
                Spacer(minLength: 0)
            }
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

