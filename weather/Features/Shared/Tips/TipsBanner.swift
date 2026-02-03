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

    @State private var selected: String? = nil

    init(tips: [String]) {
        self.tips = tips
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if let selected {
            Text(selected)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.12), value: selected)
                .accessibilityLabel(selected)
                .task(id: tipsKey) {
                    // Pick once per "tips set" change.
                    if self.selected == nil {
                        self.selected = tips.randomElement()
                    }
                }
        } else {
            // Still run selection even if the first render has no selected tip.
            Color.clear
                .frame(height: 0)
                .task(id: tipsKey) {
                    self.selected = tips.randomElement()
                }
        }
    }

    private var tipsKey: String {
        tips.joined(separator: "||")
    }
}

