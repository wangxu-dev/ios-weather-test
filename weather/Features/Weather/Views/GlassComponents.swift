//
//  GlassComponents.swift
//  weather
//
//  Small SwiftUI pieces used by the Weather feature.
//

import SwiftUI

struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.95))

            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(in: .rect(cornerRadius: 14))
    }
}

struct GlassPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary.opacity(0.95))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glassEffect()
    }
}

struct GlassNotice: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary.opacity(0.95))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

