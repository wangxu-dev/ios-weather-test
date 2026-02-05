//
//  CurrentLocationProvider.swift
//  weather
//

import Foundation
import CoreLocation

@MainActor
final class CurrentLocationProvider: NSObject, CLLocationManagerDelegate {
    enum LocationError: LocalizedError {
        case permissionDenied
        case permissionRestricted
        case unableToDeterminePermission
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "定位权限已关闭。请在系统设置中允许“使用期间”定位权限。"
            case .permissionRestricted:
                return "定位权限受限。"
            case .unableToDeterminePermission:
                return "无法确定定位权限状态。"
            case .failed(let message):
                return message
            }
        }
    }

    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentCoordinate() async throws -> CLLocationCoordinate2D {
        try await ensurePermission()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation?.resume(throwing: LocationError.failed("定位请求已被新的请求覆盖。"))
            self.continuation = continuation
            self.manager.requestLocation()
        }
    }

    private func ensurePermission() async throws {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Poll authorization status briefly; delegate is unreliable in some build contexts.
            // 50 * 50ms = 2.5s max wait.
            for _ in 0..<50 {
                let status = manager.authorizationStatus
                if status != .notDetermined { break }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                return
            case .denied:
                throw LocationError.permissionDenied
            case .restricted:
                throw LocationError.permissionRestricted
            case .notDetermined:
                throw LocationError.unableToDeterminePermission
            @unknown default:
                throw LocationError.unableToDeterminePermission
            }
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        @unknown default:
            throw LocationError.unableToDeterminePermission
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            continuation?.resume(throwing: LocationError.failed("未获取到定位结果。"))
            continuation = nil
            return
        }
        continuation?.resume(returning: location.coordinate)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
