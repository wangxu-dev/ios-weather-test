//
//  IPInfoCityLocator.swift
//  weather
//

import Foundation

/// City-locating adapter built on top of ipinfo.io response.
final class IPInfoCityLocator: CityLocating {
    private let ipLocationProvider: any IPLocationProviding
    private let normalizer: any LocationNormalizing

    init(
        ipLocationProvider: any IPLocationProviding,
        normalizer: any LocationNormalizing = DefaultLocationNormalizer()
    ) {
        self.ipLocationProvider = ipLocationProvider
        self.normalizer = normalizer
    }

    func locateCityCandidates() async throws -> CityLocationResult {
        let ipLocation = try await ipLocationProvider.fetchIPLocation()
        return CityLocationResult(
            rawLocationText: normalizer.rawLocationText(from: ipLocation),
            cityCandidates: normalizer.cityCandidates(from: ipLocation)
        )
    }
}

