//
//  BaiduIPLocationClient.swift
//  weather
//

import Foundation

/// Baidu OpenData IP location API client.
///
/// Example:
/// `https://opendata.baidu.com/api.php?query=<ip>&co=&resource_id=6006&oe=utf8`
final class BaiduIPLocationClient: IPTextLocationProviding {
    private struct Response: Decodable {
        let status: String
        let data: [Item]?

        struct Item: Decodable {
            let location: String?
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLocationText(for ip: String) async throws -> String {
        let trimmed = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw URLError(.badURL) }

        var components = URLComponents(string: "https://opendata.baidu.com/api.php")!
        components.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "co", value: ""),
            URLQueryItem(name: "resource_id", value: "6006"),
            URLQueryItem(name: "oe", value: "utf8"),
        ]
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

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == "0" else {
            throw URLError(.cannotParseResponse)
        }
        let location = decoded.data?.first?.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let location, !location.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        #if DEBUG
        print("[BaiduIPLocation] ip=\(trimmed) location=\(location)")
        #endif

        return location
    }
}

