import SwiftUI
import Observation

struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel
    @FocusState private var searchFieldFocused: Bool

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.md) {
                WeatherGlassContainer {
                    VStack(spacing: DS.Spacing.sm) {
                        header

                        if viewModel.isSearchPresented {
                            searchField
                                .transition(
                                    .asymmetric(
                                        insertion: .offset(y: -10).combined(with: .opacity),
                                        removal: .offset(y: -6).combined(with: .opacity)
                                    )
                                )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.sm)
                }
                content(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.start()
        }
        .task(id: viewModel.searchQuery) {
            guard viewModel.isSearchPresented else { return }
            await viewModel.handleSearchQueryChanged()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await viewModel.refreshAllIfNeeded(force: false) }
        }
        .alert("提示", isPresented: Binding(get: { viewModel.bannerMessage != nil }, set: { if !$0 { viewModel.bannerMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(viewModel.bannerMessage ?? "")
        }
    }

    private var background: some View {
        let colors = backgroundColors
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var backgroundColors: [Color] {
        if let state = viewModel.selectedPlace,
           case .loaded(let snapshot, _) = viewModel.weatherStates[state.id] {
            return WeatherPalette.background(
                condition: snapshot.current.condition,
                isDay: snapshot.current.isDay,
                scheme: colorScheme
            )
        }
        return WeatherPalette.background(condition: .clearSky, isDay: true, scheme: colorScheme)
    }

    private var header: some View {
        HStack(spacing: DS.Spacing.sm) {
            browsingTitle
            Spacer(minLength: 0)
            headerActionButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.primary)
        .animation(.smooth(duration: 0.32, extraBounce: 0), value: viewModel.isSearchPresented)
    }

    private var browsingTitle: some View {
        Text(viewModel.selectedPlace?.isCurrentLocation == true ? "当前位置" : (viewModel.selectedPlace?.name ?? "天气"))
            .font(DS.Typography.subtitle)
            .lineLimit(1)
            .contentTransition(.opacity)
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索城市", text: Bindable(viewModel).searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(DS.Typography.subtitle)
                .focused($searchFieldFocused)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 12)
        .weatherInteractiveGlass(in: Capsule())
    }

    private var headerActionButton: some View {
        Button(action: toggleSearch) {
            Image(systemName: viewModel.isSearchPresented ? "xmark" : "plus")
                .font(.headline)
                .symbolVariant(.none)
                .contentTransition(.opacity)
                .frame(width: 36, height: 36)
                .weatherInteractiveGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isSearchPresented ? "关闭搜索" : "添加城市")
    }

    private func content(viewModel: HomeViewModel) -> some View {
        VStack(spacing: DS.Spacing.md) {
            if viewModel.isSearchPresented {
                SearchOverlay(viewModel: viewModel)
                    .padding(.horizontal, DS.Spacing.md)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: -12).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            } else if viewModel.places.isEmpty {
                emptyState
            } else {
                cityPager(viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("点击右上角 + 添加城市")
                .font(DS.Typography.subtitle)
                .foregroundStyle(.secondary)
            Button("使用当前位置") {
                Task { await viewModel.resolveCurrentLocationAndAdd() }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .weatherInteractiveGlass(in: Capsule())
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cityPager(viewModel: HomeViewModel) -> some View {
        TabView(selection: Binding(
            get: { viewModel.selectedPlaceID ?? viewModel.places.first?.id ?? "" },
            set: { viewModel.select(placeID: $0) }
        )) {
            ForEach(viewModel.places) { place in
                ScrollView {
                    if let data = viewModelData(for: place.id) {
                        WeatherCard(data: data, state: viewModel.weatherStates[place.id] ?? .idle, onRefresh: {
                            Task { await viewModel.refresh(placeID: place.id) }
                        })
                        .padding(.horizontal, DS.Spacing.md)
                    } else {
                        WeatherCard(data: nil, state: viewModel.weatherStates[place.id] ?? .idle, onRefresh: {
                            Task { await viewModel.refresh(placeID: place.id) }
                        })
                        .padding(.horizontal, DS.Spacing.md)
                    }
                }
                .scrollIndicators(.hidden)
                .tag(place.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private func viewModelData(for id: PlaceID) -> HomeWeatherViewData? {
        guard case .loaded(let snapshot, let stale) = viewModel.weatherStates[id] else { return nil }
        return HomeWeatherViewDataMapper.map(snapshot: snapshot, isStale: stale)
    }

    private func presentSearch() {
        withAnimation(.smooth(duration: 0.34, extraBounce: 0)) {
            viewModel.showSearch()
        }
        searchFieldFocused = true
    }

    private func dismissSearch() {
        withAnimation(.smooth(duration: 0.26, extraBounce: 0)) {
            viewModel.hideSearch()
        }
        searchFieldFocused = false
    }

    private func toggleSearch() {
        viewModel.isSearchPresented ? dismissSearch() : presentSearch()
    }
}

private struct WeatherCard: View {
    let data: HomeWeatherViewData?
    let state: WeatherLoadState
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            switch state {
            case .idle:
                loadingHint("准备就绪")
            case .loading:
                loadingHint("正在刷新天气…")
            case .failed(let message):
                loadingHint(message)
            case .loaded:
                if let data {
                    loadedContent(data)
                } else {
                    loadingHint("暂无数据")
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onRefresh()
                }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
                    .font(DS.Typography.caption)
            }
            .buttonStyle(.plain)
            .padding(.top, DS.Spacing.xs)
        }
        .padding(DS.Spacing.lg)
        .background(Color.clear)
    }

    private func loadingHint(_ text: String) -> some View {
        Text(text)
            .font(DS.Typography.body)
            .foregroundStyle(.secondary)
    }

    private func loadedContent(_ data: HomeWeatherViewData) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                Text(data.subtitle)
                    .font(DS.Typography.body)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Image(systemName: data.symbolName)
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary.opacity(0.9))
            }

            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                Text(data.currentTemperature)
                    .font(DS.Typography.title)
                    .monospacedDigit()
                Text(data.highLowText)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: DS.Spacing.sm) {
                Label("更新于 \(data.updateTimeText)", systemImage: "clock")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)

                if data.isStale {
                    Text("缓存中")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.30)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                metric(title: "体感", value: data.feelsLikeText)
                metric(title: "湿度", value: data.humidityText)
                metric(title: "风速", value: data.windText)
                metric(title: "降水", value: data.precipitationText)
            }

            if !data.hourly.isEmpty {
                Divider().opacity(0.30)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("24 小时")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal) {
                        HStack(spacing: DS.Spacing.md) {
                            ForEach(data.hourly) { item in
                                VStack(spacing: DS.Spacing.xs) {
                                    Text(item.time)
                                    Text(item.temperatureText)
                                    Text(item.popText)
                                }
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.primary.opacity(0.92))
                                .frame(minWidth: 48)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }

            if !data.daily.isEmpty {
                Divider().opacity(0.30)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("未来 7 天")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                    ForEach(data.daily) { item in
                        HStack {
                            Text(item.label)
                                .frame(width: 56, alignment: .leading)
                            Text(item.conditionText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(item.minText)/\(item.maxText)")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.xs)
    }
}
