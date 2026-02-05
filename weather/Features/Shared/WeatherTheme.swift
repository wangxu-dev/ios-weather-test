//
//  WeatherTheme.swift
//  weather
//

import SwiftUI

enum WeatherTheme {
    static func backgroundColors(
        weatherCode: Int?,
        isDay: Bool?,
        colorScheme: ColorScheme
    ) -> [Color] {
        let code = weatherCode ?? -1
        let day = isDay ?? true

        switch code {
        case 0, 1:
            return day ? clearDay(colorScheme) : clearNight(colorScheme)
        case 2, 3:
            return cloudy(day: day, scheme: colorScheme)
        case 45, 48:
            return fog(day: day, scheme: colorScheme)
        case 51, 53, 55, 56, 57:
            return drizzle(day: day, scheme: colorScheme)
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return rain(day: day, scheme: colorScheme)
        case 71, 73, 75, 77, 85, 86:
            return snow(day: day, scheme: colorScheme)
        case 95, 96, 99:
            return thunder(day: day, scheme: colorScheme)
        default:
            return fallback(colorScheme)
        }
    }

    private static func clearDay(_ scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.90, green: 0.96, blue: 1.00),
                Color(red: 0.74, green: 0.90, blue: 1.00),
                Color(red: 0.62, green: 0.96, blue: 0.90),
            ]
        case .dark:
            return [
                Color(red: 0.04, green: 0.08, blue: 0.22),
                Color(red: 0.08, green: 0.22, blue: 0.48),
                Color(red: 0.10, green: 0.45, blue: 0.52),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func clearNight(_ scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.86, green: 0.90, blue: 1.00),
                Color(red: 0.80, green: 0.86, blue: 1.00),
                Color(red: 0.88, green: 0.92, blue: 1.00),
            ]
        case .dark:
            return [
                Color(red: 0.03, green: 0.03, blue: 0.10),
                Color(red: 0.12, green: 0.06, blue: 0.34),
                Color(red: 0.10, green: 0.18, blue: 0.42),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func cloudy(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.92, green: 0.94, blue: 0.98),
                Color(red: 0.82, green: 0.86, blue: 0.94),
                Color(red: 0.80, green: 0.92, blue: 0.90),
            ]
        case .dark:
            return [
                Color(red: 0.05, green: 0.06, blue: 0.12),
                Color(red: 0.12, green: 0.12, blue: 0.22),
                Color(red: 0.10, green: 0.24, blue: 0.26),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func fog(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.94, green: 0.95, blue: 0.98),
                Color(red: 0.86, green: 0.88, blue: 0.94),
                Color(red: 0.84, green: 0.92, blue: 0.94),
            ]
        case .dark:
            return [
                Color(red: 0.05, green: 0.06, blue: 0.10),
                Color(red: 0.12, green: 0.14, blue: 0.20),
                Color(red: 0.16, green: 0.18, blue: 0.24),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func drizzle(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.90, green: 0.95, blue: 0.98),
                Color(red: 0.78, green: 0.88, blue: 0.96),
                Color(red: 0.74, green: 0.94, blue: 0.92),
            ]
        case .dark:
            return [
                Color(red: 0.04, green: 0.06, blue: 0.12),
                Color(red: 0.08, green: 0.14, blue: 0.30),
                Color(red: 0.08, green: 0.30, blue: 0.34),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func rain(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.88, green: 0.94, blue: 0.98),
                Color(red: 0.70, green: 0.85, blue: 0.98),
                Color(red: 0.68, green: 0.92, blue: 0.90),
            ]
        case .dark:
            return [
                Color(red: 0.03, green: 0.06, blue: 0.14),
                Color(red: 0.06, green: 0.12, blue: 0.34),
                Color(red: 0.06, green: 0.34, blue: 0.36),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func snow(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.94, green: 0.97, blue: 1.00),
                Color(red: 0.86, green: 0.92, blue: 0.98),
                Color(red: 0.86, green: 0.98, blue: 0.96),
            ]
        case .dark:
            return [
                Color(red: 0.04, green: 0.06, blue: 0.12),
                Color(red: 0.10, green: 0.12, blue: 0.26),
                Color(red: 0.10, green: 0.26, blue: 0.24),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func thunder(day: Bool, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                Color(red: 0.90, green: 0.92, blue: 0.98),
                Color(red: 0.78, green: 0.84, blue: 0.98),
                Color(red: 0.88, green: 0.86, blue: 0.98),
            ]
        case .dark:
            return [
                Color(red: 0.03, green: 0.03, blue: 0.10),
                Color(red: 0.14, green: 0.06, blue: 0.40),
                Color(red: 0.10, green: 0.12, blue: 0.34),
            ]
        @unknown default:
            return fallback(scheme)
        }
    }

    private static func fallback(_ scheme: ColorScheme) -> [Color] {
        switch scheme {
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
}

