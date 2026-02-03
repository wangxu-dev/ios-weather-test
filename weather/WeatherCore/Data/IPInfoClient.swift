//
//  IPInfoClient.swift
//  weather
//

import Foundation

/// Minimal client for ipinfo.io.
///
/// Endpoint: `https://ipinfo.io/json`
/// Optional token support exists (you can pass a token later if needed).
final class IPInfoClient: IPLocationProviding {
    private let session: URLSession
    private let token: String?

    init(session: URLSession = .shared, token: String? = nil) {
        self.session = session
        self.token = token
    }

    func fetchIPLocation() async throws -> IPLocation {
        var components = URLComponents(string: "https://ipinfo.io/json")!
        if let token, !token.isEmpty {
            components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "token", value: token)]
        }
        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadRevalidatingCacheData
        request.timeoutInterval = 6

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        do {
            let decoded = try JSONDecoder().decode(IPLocation.self, from: data)
            #if DEBUG
            print("[IPInfoClient] ip=\(decoded.ip) country=\(decoded.country ?? "-") region=\(decoded.region ?? "-") city=\(decoded.city ?? "-") loc=\(decoded.loc ?? "-")")
            #endif
            return decoded
        } catch {
            // Keep the error simple here; callers can log raw data if needed.
            throw error
        }
    }
}

extension IPInfoClient: PublicIPProviding {
    func fetchPublicIP() async throws -> String {
        let location = try await fetchIPLocation()
        return location.ip
    }
}
