import Foundation
import CoreLocation

protocol LocationProviding: Sendable {
    func requestCoordinate() async throws -> Coordinate
}

@MainActor
final class CoreLocationProvider: NSObject, CLLocationManagerDelegate, LocationProviding {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<Coordinate, Error>?

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCoordinate() async throws -> Coordinate {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            try await Task.sleep(nanoseconds: 250_000_000)
            let status = manager.authorizationStatus
            if status == .denied {
                throw AppError.permissionDenied
            }
            if status == .restricted {
                throw AppError.permissionRestricted
            }
        case .denied:
            throw AppError.permissionDenied
        case .restricted:
            throw AppError.permissionRestricted
        @unknown default:
            throw AppError.unknown("未知定位权限状态")
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation?.resume(throwing: AppError.unknown("定位请求被覆盖"))
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            Task { @MainActor in
                continuation?.resume(throwing: AppError.unknown("未获取到定位结果"))
                continuation = nil
            }
            return
        }

        Task { @MainActor in
            continuation?.resume(returning: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: AppError.unknown(error.localizedDescription))
            continuation = nil
        }
    }
}
