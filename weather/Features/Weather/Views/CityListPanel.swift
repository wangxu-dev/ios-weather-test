//
//  CityListPanel.swift
//  weather
//

import SwiftUI

struct CityListPanel: View {
    let title: String?
    let cities: [String]
    let maxHeight: CGFloat
    let onSelect: (String) -> Void

    init(
        title: String? = nil,
        cities: [String],
        maxHeight: CGFloat = 260,
        onSelect: @escaping (String) -> Void
    ) {
        self.title = title
        self.cities = cities
        self.maxHeight = maxHeight
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(cities, id: \.self) { name in
                        Button {
                            onSelect(name)
                        } label: {
                            HStack {
                                Text(name)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if name != cities.last {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: maxHeight)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

