import Foundation

nonisolated struct PlaceID: Hashable, Codable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

nonisolated struct Coordinate: Hashable, Codable, Sendable {
    let latitude: Double
    let longitude: Double
}

nonisolated struct Place: Identifiable, Hashable, Codable, Sendable {
    let id: PlaceID
    var name: String
    var admin: String?
    var country: String?
    var coordinate: Coordinate
    var isCurrentLocation: Bool

    init(
        id: PlaceID? = nil,
        name: String,
        admin: String? = nil,
        country: String? = nil,
        coordinate: Coordinate,
        isCurrentLocation: Bool = false
    ) {
        self.name = name
        self.admin = admin
        self.country = country
        self.coordinate = coordinate
        self.isCurrentLocation = isCurrentLocation
        self.id = id ?? Place.makeStableID(
            name: name,
            admin: admin,
            country: country,
            coordinate: coordinate,
            isCurrentLocation: isCurrentLocation
        )
    }

    var displayName: String {
        var values: [String] = [name]
        if let admin, !admin.isEmpty {
            values.append(admin)
        }
        if let country, !country.isEmpty {
            values.append(country)
        }
        return values.joined(separator: " · ")
    }

    static func makeStableID(
        name: String,
        admin: String?,
        country: String?,
        coordinate: Coordinate,
        isCurrentLocation: Bool
    ) -> PlaceID {
        if isCurrentLocation {
            return PlaceID(rawValue: "current-location")
        }

        let namePart = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let adminPart = admin?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let countryPart = country?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let lat = decimalText(coordinate.latitude)
        let lon = decimalText(coordinate.longitude)
        return PlaceID(rawValue: "\(namePart)|\(adminPart)|\(countryPart)|\(lat),\(lon)")
    }

    private static func decimalText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        formatter.minimumIntegerDigits = 1
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
