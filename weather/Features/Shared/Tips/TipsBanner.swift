//
//  TipsBanner.swift
//  weather
//

import SwiftUI

/// A lightweight, reusable Tips view.
///
/// It picks one random tip from the provided list when it appears.
struct TipsBanner: View {
    let tips: [String]

    @State private var selected: String?

    init(tips: [String]) {
        let cleaned = tips
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        self.tips = cleaned
        _selected = State(initialValue: cleaned.randomElement())
    }

    var body: some View {
        Text(selected ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(selected == nil ? 0 : 1)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.12), value: selected)
            .accessibilityLabel(selected ?? "")
            .task(id: tipsKey) {
                // Only re-pick when the source tips list changes (or the current selection is invalid).
                if let selected, tips.contains(selected) {
                    return
                }
                selected = tips.randomElement()
            }
    }

    private var tipsKey: String {
        tips.joined(separator: "||")
    }
}
