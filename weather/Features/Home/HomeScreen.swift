//
//  HomeScreen.swift
//  weather
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(weatherProvider: any WeatherProviding, cityStore: any CityListStoring) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(weatherProvider: weatherProvider, cityStore: cityStore))
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GlassEffectContainer {
                ZStack {
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 10)

                        if viewModel.cities.isEmpty {
                            emptyHint
                                .padding(.horizontal)
                                .padding(.top, 16)
                        } else {
                            cityPager
                        }

                        Spacer(minLength: 0)
                    }

                    if viewModel.isAddingCity {
                        AddCityScreen(
                            citySuggester: WeatherComCnCitySuggester(cityListCache: InMemoryCityListCache.shared),
                            existingCities: viewModel.cities,
                            canClose: true,
                            onSelectCity: { city in
                                viewModel.selectCity(city)
                                viewModel.dismissAddCity()
                            },
                            onAddCity: { city in
                                viewModel.addCity(city)
                            },
                            onClose: {
                                viewModel.dismissAddCity()
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedCity) { _, newValue in
            guard let newValue else { return }
            viewModel.selectCity(newValue)
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.isAddingCity)
    }

    private var topBar: some View {
        HStack {
            Text("天气")
                .font(.title3.weight(.semibold))

            Spacer(minLength: 0)

            Button {
                viewModel.presentAddCity()
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("添加城市")
        }
        .foregroundStyle(.primary)
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
