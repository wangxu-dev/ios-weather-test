import Foundation

nonisolated actor OpenMeteoWeatherRepository: WeatherRepository {
    private let session: URLSession
    private let placeRepository: PlaceRepository

    init(session: URLSession = .shared, placeRepository: PlaceRepository) {
        self.session = session
        self.placeRepository = placeRepository
    }

    func fetchWeather(for placeID: PlaceID) async throws -> WeatherSnapshot {
        guard let place = await placeRepository.place(for: placeID) else {
            throw AppError.notFound("城市")
        }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(place.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(place.coordinate.longitude)),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,pressure_msl,visibility,wind_gusts_10m,is_day,wind_speed_10m,wind_direction_10m"
            ),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "ms"),
            URLQueryItem(name: "precipitation_unit", value: "mm"),
        ]

        let request = URLRequest(url: components.url!, timeoutInterval: 10)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.network("天气请求失败")
        }

        let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        return try OpenMeteoMapper.mapForecast(place: place, response: decoded)
    }
}
