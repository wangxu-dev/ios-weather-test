import SwiftUI

enum DS {
    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Radius {
        static let card: CGFloat = 24
        static let panel: CGFloat = 18
        static let chip: CGFloat = 14
    }

    enum Typography {
        static let title = Font.system(.largeTitle, design: .rounded).weight(.semibold)
        static let subtitle = Font.title3.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption.weight(.semibold)
    }
}

enum WeatherPalette {
    static func background(condition: WeatherConditionCode, isDay: Bool, scheme: ColorScheme) -> [Color] {
        switch (condition, isDay, scheme) {
        case (.clearSky, true, .light):
            return [Color(red: 0.88, green: 0.96, blue: 1.0), Color(red: 0.58, green: 0.86, blue: 1.0), Color(red: 0.50, green: 0.92, blue: 0.86)]
        case (.clearSky, _, .dark):
            return [Color(red: 0.03, green: 0.08, blue: 0.24), Color(red: 0.08, green: 0.24, blue: 0.50), Color(red: 0.10, green: 0.40, blue: 0.48)]
        case (_, _, .dark):
            return [Color(red: 0.05, green: 0.06, blue: 0.12), Color(red: 0.10, green: 0.14, blue: 0.28), Color(red: 0.12, green: 0.24, blue: 0.32)]
        default:
            return [Color(red: 0.92, green: 0.95, blue: 0.99), Color(red: 0.78, green: 0.87, blue: 0.96), Color(red: 0.74, green: 0.92, blue: 0.90)]
        }
    }
}
