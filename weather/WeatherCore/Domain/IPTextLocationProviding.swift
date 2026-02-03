//
//  IPTextLocationProviding.swift
//  weather
//

import Foundation

/// Resolves an IP address to a human-readable location string (provider-specific format).
protocol IPTextLocationProviding: Sendable {
    func fetchLocationText(for ip: String) async throws -> String
}

