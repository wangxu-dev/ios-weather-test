import Foundation
import Observation

@MainActor
@Observable
final class WeatherAppEnvironment {
    let homeViewModel: HomeViewModel

    init() {
        let locationProvider = CoreLocationProvider()
        let placeRepository = OpenMeteoPlaceRepository(locationProvider: locationProvider)
        let weatherRepository = OpenMeteoWeatherRepository(placeRepository: placeRepository)
        let placeStore = UserDefaultsPlaceStore()
        let cacheStore = UserDefaultsWeatherCacheStore()
        let useCase = HomeUseCase(
            placeRepository: placeRepository,
            weatherRepository: weatherRepository,
            placeStore: placeStore,
            cacheStore: cacheStore
        )

        self.homeViewModel = HomeViewModel(useCase: useCase, aiProvider: NoopAIProvider())
    }
}
