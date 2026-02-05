//
//  HomeScreen.swift
//  weather
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var searchModel: CitySearchViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSearching: Bool = false
    @State private var resignSearchToken = UUID()
    @State private var focusSearchToken: UUID? = nil
    @State private var pageScrollMinY: [String: CGFloat] = [:]

    init(weatherProvider: any WeatherProviding, cityStore: any CityListStoring) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                weatherProvider: weatherProvider,
                cityStore: cityStore,
                weatherCacheStore: UserDefaultsWeatherCacheStore.shared
            )
        )

        let citySuggester = WeatherComCnCitySuggester()
        _searchModel = StateObject(wrappedValue: CitySearchViewModel(citySuggester: citySuggester))
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GlassEffectContainer {
                ZStack(alignment: .top) {
                    content

                    topBar
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                        // glassEffect may render in a separate layer; compositingGroup ensures opacity applies to the whole bar.
                        .compositingGroup()
                        .opacity(topBarOpacity)
                        .allowsHitTesting(topBarOpacity > 0.01)
                }
            }
        }
        .onTapGesture {
            guard isSearching else { return }
            resignSearchToken = UUID()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            guard !isSearching else { return }
            viewModel.refreshAllCities()
        }
        .onPreferenceChange(PageScrollMinYPreferenceKey.self) { dict in
            pageScrollMinY.merge(dict) { _, new in new }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            if isSearching {
                searchScene
                    .padding(.horizontal)
                    .padding(.top, topBarTotalHeight)
                    .transition(.opacity)
            } else if viewModel.cities.isEmpty {
                emptyHint
                    .padding(.horizontal)
                    .padding(.top, topBarTotalHeight + 8)
                    .transition(.opacity)
            } else {
                cityPager
                    .padding(.top, 0)
                    .transition(.opacity.combined(with: .scale(scale: 0.99, anchor: .top)))
            }

            Spacer(minLength: 0)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if isSearching {
                searchField
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)

                closeButton
                    .transition(.opacity)
            } else {
                Text(viewModel.selectedCity ?? "天气")
                    .font(.title3.weight(.semibold))
                    .transition(.opacity)

                Spacer(minLength: 0)

                addButton
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .foregroundStyle(.primary)
        // Keep header and search scene switching in sync even if state changes
        // happen without an explicit withAnimation call.
        .animation(.spring(response: 0.40, dampingFraction: 0.92, blendDuration: 0.10), value: isSearching)
    }

    private var addButton: some View {
        Button {
            enterSearch()
        } label: {
            CircleIcon(symbolName: "plus")
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableIconButtonStyle())
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
        .frame(height: 44)
    }

    private var closeButton: some View {
        Button {
            exitSearch()
        } label: {
            CircleIcon(symbolName: "xmark")
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableIconButtonStyle())
        .accessibilityLabel("关闭搜索")
    }

    @ViewBuilder
    private var searchScene: some View {
        let trimmed = searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines)

        let mode = searchSceneMode(trimmedQuery: trimmed)
        let showNoResults =
            !trimmed.isEmpty
            && !searchModel.isSearching
            && !searchModel.isDebouncing
            && searchModel.suggestions.isEmpty
            && searchModel.lastCompletedQuery == trimmed

        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .top) {
                switch mode {
                case .addedCities:
                    VStack(alignment: .leading, spacing: 10) {
                        HomeSearchList(
                            recommendation: nil,
                            cities: viewModel.cities,
                            maxHeight: 280,
                            enableDelete: true,
                            onSelect: { name in
                                resignSearchToken = UUID()
                                if viewModel.cities.contains(name) {
                                    viewModel.selectCity(name)
                                } else {
                                    viewModel.addCity(name)
                                }
                                exitSearch()
                            },
                            onDelete: { name in
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.90, blendDuration: 0.10)) {
                                    viewModel.removeCity(name)
                                }
                            }
                        )

                        TipsBanner(tips: TipLibrary.shared.tips(for: .searchAddedCities))
                            .padding(.horizontal, 4)
                    }
                    .padding(.top, 6)
                    .transition(.opacity)

                case .suggestions:
                    HomeSearchList(
                        recommendation: nil,
                        cities: searchModel.suggestions,
                        maxHeight: 360,
                        enableDelete: false,
                        onSelect: { name in
                            resignSearchToken = UUID()
                            if viewModel.cities.contains(name) {
                                viewModel.selectCity(name)
                            } else {
                                viewModel.addCity(name)
                            }
                            exitSearch()
                        }
                    )
                    .padding(.top, 6)
                    .transition(.opacity)

                case .searching, .noResults, .empty:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.12), value: mode)

            // Only show "no results" after a completed search for the current query.
            // We intentionally do not show a "searching..." hint to avoid any perceived flicker
            // during fast, debounced searches.
            Text("无匹配城市")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showNoResults ? 1 : 0)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.12), value: showNoResults)
        }
    }

    private enum SearchSceneMode: Hashable {
        case empty
        case addedCities
        case searching
        case suggestions
        case noResults
    }

    private func searchSceneMode(trimmedQuery: String) -> SearchSceneMode {
        if trimmedQuery.isEmpty {
            return viewModel.cities.isEmpty ? .empty : .addedCities
        }

        if !searchModel.suggestions.isEmpty {
            return .suggestions
        }

        if searchModel.isDebouncing || searchModel.isSearching {
            return .searching
        }

        // Only show "no results" if the search has completed for the current query.
        // This avoids flashing "no results" while the user is still typing (debounced search not started yet).
        if searchModel.lastCompletedQuery == trimmedQuery {
            return .noResults
        }

        return .searching
    }

    private var cityPager: some View {
        TabView(selection: Binding(
            get: { viewModel.selectedCity ?? viewModel.cities.first ?? "" },
            set: { viewModel.selectCity($0) }
        )) {
            ForEach(viewModel.cities, id: \.self) { city in
                ScrollView {
                    PageScrollMinYReporter(city: city, coordinateSpaceName: "HomeScroll-\(city)")
                    // Space for the overlayed top bar. This scrolls away as you scroll up,
                    // so content can reach the top without being covered by an always-on header.
                    Color.clear
                        .frame(height: topBarTotalHeight)

                    WeatherCardView(
                        city: city,
                        state: viewModel.weatherByCity[city] ?? .idle,
                        isRefreshing: viewModel.refreshingCities.contains(city)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 2)
                }
                .coordinateSpace(name: "HomeScroll-\(city)")
                .scrollIndicators(.hidden)
                .tag(city)
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
        withAnimation(.spring(response: 0.40, dampingFraction: 0.92, blendDuration: 0.10)) {
            isSearching = true
        }
        focusSearchToken = UUID()
    }

    private func exitSearch() {
        resignSearchToken = UUID()
        focusSearchToken = nil
        searchModel.clear()
        withAnimation(.spring(response: 0.40, dampingFraction: 0.92, blendDuration: 0.10)) {
            isSearching = false
        }
    }

    private func submitCurrentQuery() {
        let trimmed = searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Prevent selecting from stale suggestions while a new query is still searching.
        guard !searchModel.isSearching else { return }

        // Only allow adding/selecting cities that are known to the data source.
        // 1) If user already added it, just select.
        if viewModel.cities.contains(trimmed) {
            resignSearchToken = UUID()
            viewModel.selectCity(trimmed)
            exitSearch()
            return
        }

        // 2) If there is an exact match in current suggestions, accept it.
        if let exact = searchModel.suggestions.first(where: { $0 == trimmed }) {
            resignSearchToken = UUID()
            viewModel.addCity(exact)
            exitSearch()
            return
        }

        // 3) If there is exactly one suggestion, accept it.
        if searchModel.suggestions.count == 1, let only = searchModel.suggestions.first {
            resignSearchToken = UUID()
            viewModel.addCity(only)
            exitSearch()
            return
        }

        // Otherwise, require the user to tap one of the suggestions.
    }

    private var currentCity: String {
        viewModel.selectedCity ?? viewModel.cities.first ?? ""
    }

    private var topBarFadeProgress: CGFloat {
        // Only fade while not searching, and only when there's content to scroll.
        guard !isSearching else { return 0 }
        guard !viewModel.cities.isEmpty else { return 0 }

        // `minY` starts near 0 and becomes negative as you scroll up.
        let minY = pageScrollMinY[currentCity] ?? 0
        let threshold: CGFloat = 44
        let delta = max(0, -minY)
        return min(1, delta / threshold)
    }

    private var topBarOpacity: CGFloat {
        // Fade out completely while scrolling up.
        max(0, 1 - topBarFadeProgress)
    }

    private var topBarTotalHeight: CGFloat {
        // 44 content height + 4 top + 4 bottom.
        52
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

private struct PageScrollMinYPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct PageScrollMinYReporter: View {
    let city: String
    let coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: PageScrollMinYPreferenceKey.self,
                    value: [city: proxy.frame(in: .named(coordinateSpaceName)).minY]
                )
        }
        .frame(height: 0)
    }
}

private struct CircleIcon: View {
    let symbolName: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 16, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .frame(width: 36, height: 36, alignment: .center)
            .glassEffect(in: .circle)
    }
}

private struct PressableIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.78, blendDuration: 0.06), value: configuration.isPressed)
    }
}

#if DEBUG
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(
            weatherProvider: MockWeatherProvider(),
            cityStore: UserDefaultsCityListStore()
        )
    }
}
#endif
