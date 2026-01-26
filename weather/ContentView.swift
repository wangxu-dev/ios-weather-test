//
//  ContentView.swift
//  weather
//
//  Created by xu on 2026/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: WeatherViewModel

    init(weatherProvider: any WeatherProviding) {
        _viewModel = StateObject(wrappedValue: WeatherViewModel(weatherProvider: weatherProvider))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("城市名（例如：北京）", text: $viewModel.city)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    Button("查询") {
                        viewModel.fetchWeather()
                    }
                    .buttonStyle(.borderedProminent)
                }

                content

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("天气")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("输入城市名，点击“查询”。")
                .foregroundStyle(.secondary)

        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("加载中…")
                    .foregroundStyle(.secondary)
            }

        case .loaded(let payload):
            if let info = payload.weatherInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(info.city)  \(info.weather)")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("更新时间：\(info.updateTime)")
                        .foregroundStyle(.secondary)

                    Text("温度：\(info.tempLow) ~ \(info.tempHigh)")
                    Text("风：\(info.windDirection) \(info.windScale)")
                }
            } else {
                Text("没有拿到 weatherInfo。")
                    .foregroundStyle(.secondary)
            }

            if !payload.alarms.isEmpty {
                Divider()

                Text("预警")
                    .font(.headline)

                List(payload.alarms) { alarm in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.title)
                            .fontWeight(.semibold)
                        Text(alarm.type)
                            .foregroundStyle(.secondary)
                        Text(alarm.publishTime)
                            .foregroundStyle(.secondary)
                        Text(alarm.details)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }

        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text("请求失败")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView(weatherProvider: MockWeatherProvider())
}
