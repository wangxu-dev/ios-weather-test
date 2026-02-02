//
//  AddCityScreen.swift
//  weather
//

import SwiftUI

struct AddCityScreen: View {
    @StateObject private var viewModel: AddCityViewModel
    @State private var resignSearchToken = UUID()
    @Environment(\.colorScheme) private var colorScheme

    let existingCities: [String]
    let canClose: Bool
    let onSelectCity: (String) -> Void
    let onAddCity: (String) -> Void
    let onClose: () -> Void

    init(
        citySuggester: any CitySuggesting,
        existingCities: [String],
        canClose: Bool,
        onSelectCity: @escaping (String) -> Void,
        onAddCity: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: AddCityViewModel(citySuggester: citySuggester))
        self.existingCities = existingCities
        self.canClose = canClose
        self.onSelectCity = onSelectCity
        self.onAddCity = onAddCity
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GlassEffectContainer {
                VStack(spacing: 12) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 14)

                    SystemSearchField(
                        placeholder: "搜索可添加城市",
                        text: $viewModel.query,
                        resignToken: resignSearchToken,
                        onFocusChanged: { _ in },
                        onSubmit: { handleSubmit() }
                    )
                    .frame(height: 44)
                    .padding(.horizontal)

                    content
                        .padding(.horizontal)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    resignSearchToken = UUID()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("添加城市")
                .font(.headline)

            Spacer(minLength: 0)

            if canClose {
                Button {
                    resignSearchToken = UUID()
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭")
            }
        }
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var content: some View {
        let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if !existingCities.isEmpty {
                CityListPanel(title: "已添加", cities: existingCities, maxHeight: 360, style: .plain) { name in
                    resignSearchToken = UUID()
                    onSelectCity(name)
                }
            } else {
                EmptyView()
            }
        } else {
            if !viewModel.suggestions.isEmpty {
                CityListPanel(title: "搜索结果", cities: viewModel.suggestions, maxHeight: 420, style: .plain) { name in
                    resignSearchToken = UUID()
                    if existingCities.contains(name) {
                        onSelectCity(name)
                    } else {
                        onAddCity(name)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    private func handleSubmit() {
        let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        resignSearchToken = UUID()
        if existingCities.contains(trimmed) {
            onSelectCity(trimmed)
        } else {
            onAddCity(trimmed)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundColors: [Color] {
        switch colorScheme {
        case .light:
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
}

#Preview {
    AddCityScreen(
        citySuggester: WeatherComCnCitySuggester(),
        existingCities: ["北京", "上海"],
        canClose: true,
        onSelectCity: { _ in },
        onAddCity: { _ in },
        onClose: {}
    )
}
