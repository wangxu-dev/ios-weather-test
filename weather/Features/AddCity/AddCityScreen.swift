//
//  AddCityScreen.swift
//  weather
//

import SwiftUI

struct AddCityScreen: View {
    @StateObject private var viewModel: AddCityViewModel
    @State private var resignSearchToken = UUID()
    @Environment(\.colorScheme) private var colorScheme

    let existingPlaces: [Place]
    let canClose: Bool
    let onSelectPlace: (Place) -> Void
    let onAddPlace: (Place) -> Void
    let onClose: () -> Void

    init(
        citySuggester: any CitySuggesting,
        existingPlaces: [Place],
        canClose: Bool,
        onSelectPlace: @escaping (Place) -> Void,
        onAddPlace: @escaping (Place) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: AddCityViewModel(citySuggester: citySuggester))
        self.existingPlaces = existingPlaces
        self.canClose = canClose
        self.onSelectPlace = onSelectPlace
        self.onAddPlace = onAddPlace
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
            if !existingPlaces.isEmpty {
                CityListPanel(title: "已添加", cities: existingPlaces.map(\.displayName), maxHeight: 360, style: .plain) { name in
                    resignSearchToken = UUID()
                    if let place = existingPlaces.first(where: { $0.displayName == name }) {
                        onSelectPlace(place)
                    }
                }
            } else {
                EmptyView()
            }
        } else {
            if !viewModel.suggestions.isEmpty {
                CityListPanel(title: "搜索结果", cities: viewModel.suggestions.map(\.displayName), maxHeight: 420, style: .plain) { name in
                    resignSearchToken = UUID()
                    if let selected = viewModel.suggestions.first(where: { $0.displayName == name }) {
                        if existingPlaces.contains(where: { $0.id == selected.id }) {
                            onSelectPlace(selected)
                        } else {
                            onAddPlace(selected)
                        }
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
        onAddPlace(Place(name: trimmed))
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

#if DEBUG
struct AddCityScreen_Previews: PreviewProvider {
    static var previews: some View {
        AddCityScreen(
            citySuggester: WeatherComCnCitySuggester(),
            existingPlaces: [Place(name: "北京"), Place(name: "上海")],
            canClose: true,
            onSelectPlace: { _ in },
            onAddPlace: { _ in },
            onClose: {}
        )
    }
}
#endif
