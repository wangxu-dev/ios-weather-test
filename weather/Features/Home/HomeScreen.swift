//
//  HomeScreen.swift
//  weather
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var searchModel: CitySearchViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSearching: Bool = false
    @State private var resignSearchToken = UUID()
    @State private var focusSearchToken: UUID? = nil
    @Namespace private var searchMorphNamespace

    init(weatherProvider: any WeatherProviding, cityStore: any CityListStoring) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(weatherProvider: weatherProvider, cityStore: cityStore))
        _searchModel = StateObject(
            wrappedValue: CitySearchViewModel(
                citySuggester: WeatherComCnCitySuggester(cityListCache: InMemoryCityListCache.shared)
            )
        )
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GlassEffectContainer {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 10)

                    if isSearching {
                        searchScene
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        if viewModel.cities.isEmpty {
                            emptyHint
                                .padding(.horizontal)
                                .padding(.top, 16)
                                .transition(.opacity)
                        } else {
                            cityPager
                                .transition(.opacity.combined(with: .scale(scale: 0.99, anchor: .top)))
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .onTapGesture {
            guard isSearching else { return }
            resignSearchToken = UUID()
        }
        .animation(.spring(response: 0.46, dampingFraction: 0.88, blendDuration: 0.12), value: isSearching)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if isSearching {
                searchField
                    .frame(maxWidth: .infinity)
                    .transition(.identity)
            } else {
                Text("天气")
                    .font(.title3.weight(.semibold))

                Spacer(minLength: 0)

                addButton
                    .transition(.identity)
            }

            if isSearching {
                cancelButton
                    .transition(.opacity)
            }
        }
        .foregroundStyle(.primary)
    }

    private var addButton: some View {
        Button {
            enterSearch()
        } label: {
            Image(systemName: "plus")
                .font(.headline)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .matchedGeometryEffect(id: "searchBackground", in: searchMorphNamespace)
        )
        .accessibilityLabel("添加城市")
    }

    private var searchField: some View {
        SystemSearchField(
            placeholder: "搜索城市",
            text: $searchModel.query,
            resignToken: resignSearchToken,
            focusToken: focusSearchToken,
            onFocusChanged: { _ in },
            onSubmit: { submitCurrentQuery() }
        )
        .frame(height: 40)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .matchedGeometryEffect(id: "searchBackground", in: searchMorphNamespace)
        )
    }

    private var cancelButton: some View {
        Button("取消") {
            exitSearch()
        }
        .buttonStyle(.plain)
        .font(.headline.weight(.semibold))
        .contentTransition(.opacity)
    }

    @ViewBuilder
    private var searchScene: some View {
        let trimmed = searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(spacing: 12) {
            if trimmed.isEmpty {
                if !viewModel.cities.isEmpty {
                    CityListPanel(
                        title: nil,
                        cities: viewModel.cities,
                        maxHeight: 320,
                        style: .plain
                    ) { name in
                        resignSearchToken = UUID()
                        viewModel.selectCity(name)
                        exitSearch()
                    }
                } else {
                    EmptyView()
                }
            } else {
                if !searchModel.suggestions.isEmpty {
                    CityListPanel(
                        title: nil,
                        cities: searchModel.suggestions,
                        maxHeight: 420,
                        style: .plain
                    ) { name in
                        resignSearchToken = UUID()
                        if viewModel.cities.contains(name) {
                            viewModel.selectCity(name)
                        } else {
                            viewModel.addCity(name)
                        }
                        exitSearch()
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .padding(.top, 6)
    }

    private var cityPager: some View {
        TabView(selection: Binding(
            get: { viewModel.selectedCity ?? viewModel.cities.first ?? "" },
            set: { viewModel.selectCity($0) }
        )) {
            ForEach(viewModel.cities, id: \.self) { city in
                WeatherCardView(
                    city: city,
                    state: viewModel.weatherByCity[city] ?? .idle,
                    onRefresh: {
                        viewModel.fetchWeather(for: city)
                    }
                )
                .tag(city)
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private var emptyHint: some View {
        Text("点击右上角“+”添加城市")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func enterSearch() {
        isSearching = true
        focusSearchToken = UUID()
    }

    private func exitSearch() {
        resignSearchToken = UUID()
        focusSearchToken = nil
        searchModel.clear()
        isSearching = false
    }

    private func submitCurrentQuery() {
        let trimmed = searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        resignSearchToken = UUID()
        if viewModel.cities.contains(trimmed) {
            viewModel.selectCity(trimmed)
        } else {
            viewModel.addCity(trimmed)
        }
        exitSearch()
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

    private var shadowColor: Color {
        switch colorScheme {
        case .light:
            return Color.black.opacity(0.10)
        case .dark:
            return Color.black.opacity(0.18)
        @unknown default:
            return Color.black.opacity(0.14)
        }
    }
}

#Preview {
    HomeScreen(
        weatherProvider: MockWeatherProvider(),
        cityStore: UserDefaultsCityListStore()
    )
}
