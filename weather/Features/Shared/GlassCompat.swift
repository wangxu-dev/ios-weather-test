//
//  GlassCompat.swift
//  weather
//

import SwiftUI

/// Wrap iOS 26 glass APIs with an iOS 18+ fallback.
struct WeatherGlassEffectContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                content()
            }
        } else {
            content()
        }
    }
}

extension View {
    func weatherGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(in: shape))
        }

        return AnyView(
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(
                    shape
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                )
        )
    }
}
