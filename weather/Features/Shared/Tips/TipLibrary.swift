//
//  TipLibrary.swift
//  weather
//

import Foundation

enum TipContext: Hashable {
    case home
    case searchAddedCities
}

struct TipItem: Hashable {
    let text: String
    let contexts: Set<TipContext>
}

/// Central place to manage user-facing Tips, so different screens can reuse them.
struct TipLibrary {
    static let shared = TipLibrary()

    private let items: [TipItem] = [
        TipItem(
            text: "Tips：长按城市可从首页移除",
            contexts: [.searchAddedCities]
        ),
        TipItem(
            text: "Tips：左右滑动可切换城市",
            contexts: [.home]
        ),
    ]

    func tips(for context: TipContext) -> [String] {
        items
            .filter { $0.contexts.contains(context) }
            .map(\.text)
    }
}
