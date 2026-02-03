//
//  IPInfoBaiduCityLocator.swift
//  weather
//

import Foundation

/// City locator that:
/// 1) fetches public IP via ipinfo
/// 2) resolves the IP to a CN location string via Baidu OpenData
/// 3) extracts city candidates from the CN location string
final class IPInfoBaiduCityLocator: CityLocating {
    private let ipProvider: any PublicIPProviding
    private let locationProvider: any IPTextLocationProviding
    private let normalizer: any LocationNormalizing

    init(
        ipProvider: any PublicIPProviding,
        locationProvider: any IPTextLocationProviding,
        normalizer: any LocationNormalizing = DefaultLocationNormalizer()
    ) {
        self.ipProvider = ipProvider
        self.locationProvider = locationProvider
        self.normalizer = normalizer
    }

    func locateCityCandidates() async throws -> CityLocationResult {
        let ip = try await ipProvider.fetchPublicIP()
        let locationText = try await locationProvider.fetchLocationText(for: ip)

        return CityLocationResult(
            rawLocationText: normalizer.rawLocationText(from: locationText),
            cityCandidates: normalizer.cityCandidates(from: locationText)
        )
    }
}

