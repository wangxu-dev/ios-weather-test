//
//  AddCityScreen.swift
//  weather
//

import SwiftUI

struct AddCityScreen: View {
    @StateObject private var viewModel: AddCityViewModel
    @State private var resignSearchToken = UUID()

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

    private var header: some View {
        HStack {
            Text("添加城市")
                .font(.headline)

            Spacer(minLength: 0)

            if canClose {
                Button("关闭") {
                    resignSearchToken = UUID()
                    onClose()
                }
                .buttonStyle(.plain)
                .fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if !existingCities.isEmpty {
                CityListPanel(title: "已添加", cities: existingCities, maxHeight: 360) { name in
                    resignSearchToken = UUID()
                    onSelectCity(name)
                }
            } else {
                EmptyView()
            }
        } else {
            CityListPanel(title: "搜索结果", cities: viewModel.suggestions, maxHeight: 420) { name in
                resignSearchToken = UUID()
                if existingCities.contains(name) {
                    onSelectCity(name)
                } else {
                    onAddCity(name)
                }
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
