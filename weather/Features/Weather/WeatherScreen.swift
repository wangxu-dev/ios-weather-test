//
//  WeatherScreen.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import SwiftUI

struct WeatherScreen: View {
    @StateObject private var viewModel: WeatherViewModel
    @State private var resignSearchToken = UUID()
    @Environment(\.colorScheme) private var colorScheme

    init(
        weatherProvider: any WeatherProviding,
        citySuggester: any CitySuggesting,
        recentCitiesStore: any RecentCitiesStoring
    ) {
        _viewModel = StateObject(
            wrappedValue: WeatherViewModel(
                weatherProvider: weatherProvider,
                citySuggester: citySuggester,
                recentCitiesStore: recentCitiesStore
            )
        )
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.shouldShowContent {
                            contentCard
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .top, spacing: 0) {
                    topSearchArea
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                }
                // Footer removed for now.
                // .safeAreaInset(edge: .bottom, spacing: 0) {
                //     footer
                //         .padding(.bottom, 10)
                // }
            }
        }
        .onTapGesture {
            resignSearchToken = UUID()
            viewModel.setSearchFocused(false)
        }
    }

    private var background: some View {
        // Keep the vibe consistent, but adapt contrast for Light/Dark.
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundColors: [Color] {
        switch colorScheme {
        case .light:
            // Softer, brighter tones so the system search field and text feel native in Light mode.
            return [
                Color(red: 0.92, green: 0.96, blue: 1.00),
                Color(red: 0.92, green: 0.93, blue: 1.00),
                Color(red: 0.86, green: 0.98, blue: 0.94),
            ]
        case .dark:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.18, green: 0.06, blue: 0.48),
                Color(red: 0.26, green: 0.79, blue: 0.68),
            ]
        @unknown default:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.18, green: 0.06, blue: 0.48),
                Color(red: 0.26, green: 0.79, blue: 0.68),
            ]
        }
    }

    private var searchBar: some View {
        SystemSearchField(
            placeholder: "输入城市名",
            text: $viewModel.city,
            resignToken: resignSearchToken,
            onFocusChanged: { isFocused in
                viewModel.setSearchFocused(isFocused)
            },
            onSubmit: {
                viewModel.fetchWeather()
            }
        )
        .frame(height: 44)
    }

    private var topSearchArea: some View {
        VStack(spacing: 8) {
            searchBar
            
            switch viewModel.overlayKind {
            case .none:
                EmptyView()
            case .suggestions:
                suggestionsPanel
            case .history:
                recentPanel
            }
        }
    }

    private var suggestionsPanel: some View {
        CityListPanel(cities: viewModel.citySuggestions) { name in
            resignSearchToken = UUID()
            viewModel.setSearchFocused(false)
            viewModel.selectSuggestion(name)
        }
    }

    private var recentPanel: some View {
        CityListPanel(title: "最近", cities: viewModel.recentCities) { name in
            resignSearchToken = UUID()
            viewModel.setSearchFocused(false)
            viewModel.selectRecentCity(name)
        }
    }

    private var contentCard: some View {
        VStack(spacing: 12) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 8)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .loading:
            GlassNotice(
                systemImage: "hourglass",
                title: "加载中",
                message: "正在获取天气数据…"
            )
            .frame(maxWidth: .infinity, alignment: .leading)

        case .loaded(let payload):
            loadedView(payload)

        case .failed(let message):
            GlassNotice(
                systemImage: "exclamationmark.triangle.fill",
                title: "请求失败",
                message: message
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loadedView(_ payload: WeatherPayload) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if let info = payload.weatherInfo {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.city)
                            .font(.title2.weight(.semibold))
                        Text(info.weather)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: symbolName(for: info.weather))
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary.opacity(0.92))
                            .shadow(color: .black.opacity(0.22), radius: 14, y: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(info.tempHigh)°")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())

                            Text("最低 \(info.tempLow)°")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary.opacity(0.95))
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
            } else {
                Text("没有拿到 weatherInfo。")
                    .foregroundStyle(.secondary)
            }

            if !payload.alarms.isEmpty {
                Divider()

                DisclosureGroup {
                    VStack(spacing: 10) {
                        ForEach(payload.alarms) { alarm in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(alarm.title)
                                    .fontWeight(.semibold)
                                Text(alarm.type)
                                    .foregroundStyle(.secondary)
                                Text(alarm.publishTime)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                Text(alarm.details)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .glassEffect(in: .rect(cornerRadius: 16))
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.hierarchical)
                        Text("预警")
                            .font(.headline)
                        Spacer(minLength: 0)
                    }
                }
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

    private var footer: some View {
        Text("数据来自 weather.com.cn，仅供参考。")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect()
            .accessibilityLabel("数据来源：weather.com.cn，仅供参考")
    }
}

#Preview {
    WeatherScreen(
        weatherProvider: MockWeatherProvider(),
        citySuggester: WeatherComCnCitySuggester(),
        recentCitiesStore: UserDefaultsRecentCitiesStore()
    )
}
