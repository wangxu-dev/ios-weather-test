//
//  PublicIPProviding.swift
//  weather
//

import Foundation

protocol PublicIPProviding: Sendable {
    func fetchPublicIP() async throws -> String
}

