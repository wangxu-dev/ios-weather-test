//
//  HomeSearchList.swift
//  weather
//

import SwiftUI

struct HomeSearchList: View {
    struct LocationRecommendation: Hashable, Sendable {
        var city: String
    }

    let recommendation: LocationRecommendation?
    let cities: [String]
    let maxHeight: CGFloat
    let enableDelete: Bool
    let onSelect: (String) -> Void
    let onDelete: ((String) -> Void)?

    init(
        recommendation: LocationRecommendation?,
        cities: [String],
        maxHeight: CGFloat,
        enableDelete: Bool,
        onSelect: @escaping (String) -> Void,
        onDelete: ((String) -> Void)? = nil
    ) {
        self.recommendation = recommendation
        self.cities = cities
        self.maxHeight = maxHeight
        self.enableDelete = enableDelete
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    var body: some View {
        List {
            if let recommendation {
                Button {
                    onSelect(recommendation.city)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        Text("定位推荐：\(recommendation.city)")
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color(uiColor: .separator).opacity(0.35))
            }

            ForEach(cities, id: \.self) { name in
                Button {
                    onSelect(name)
                } label: {
                    HStack {
                        Text(name)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color(uiColor: .separator).opacity(0.35))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if enableDelete, let onDelete {
                        Button(role: .destructive) {
                            onDelete(name)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxHeight: maxHeight)
    }
}
