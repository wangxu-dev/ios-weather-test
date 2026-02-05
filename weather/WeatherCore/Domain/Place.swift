//
//  Place.swift
//  weather
//

import Foundation

/// A user-facing place that can be used to query weather.
///
/// - If `latitude/longitude` are present, the app can query forecast directly.
/// - If missing (legacy entries), a provider may geocode by `name`.
struct Place: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var country: String?
    var admin1: String?
    var latitude: Double?
    var longitude: Double?

    init(
        id: String? = nil,
        name: String,
        country: String? = nil,
        admin1: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.name = name
        self.country = country
        self.admin1 = admin1
        self.latitude = latitude
        self.longitude = longitude
        self.id = id ?? Place.makeStableId(
            name: name,
            country: country,
            admin1: admin1,
            latitude: latitude,
            longitude: longitude
        )
    }

    var displayName: String {
        var parts: [String] = [name]
        if let admin1, !admin1.isEmpty { parts.append(admin1) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: " · ")
    }

    private static func makeStableId(
        name: String,
        country: String?,
        admin1: String?,
        latitude: Double?,
        longitude: Double?
    ) -> String {
        if let latitude, let longitude {
            // Round to keep IDs stable across minor float representation differences.
            let lat = String(format: "%.4f", latitude)
            let lon = String(format: "%.4f", longitude)
            return "coords:\(lat),\(lon)"
        }

        var normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let admin1, !admin1.isEmpty {
            normalized += "|\(admin1.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        }
        if let country, !country.isEmpty {
            normalized += "|\(country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        }
        return "name:\(normalized)"
    }
}

