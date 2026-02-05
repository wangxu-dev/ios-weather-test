//
//  HomeSearchList.swift
//  weather
//

import SwiftUI

struct HomeSearchList: View {
    struct PrimaryAction: Hashable {
        var title: String
        var systemImage: String
    }

    let primaryAction: PrimaryAction?
    let places: [Place]
    let maxHeight: CGFloat
    let enableDelete: Bool
    let onSelect: (Place) -> Void
    let onDelete: ((Place) -> Void)?
    let onPrimaryAction: (() -> Void)?

    init(
        primaryAction: PrimaryAction?,
        places: [Place],
        maxHeight: CGFloat,
        enableDelete: Bool,
        onSelect: @escaping (Place) -> Void,
        onDelete: ((Place) -> Void)? = nil,
        onPrimaryAction: (() -> Void)? = nil
    ) {
        self.primaryAction = primaryAction
        self.places = places
        self.maxHeight = maxHeight
        self.enableDelete = enableDelete
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onPrimaryAction = onPrimaryAction
    }

    var body: some View {
        List {
            if let primaryAction, let onPrimaryAction {
                Button {
                    onPrimaryAction()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: primaryAction.systemImage)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        Text(primaryAction.title)
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

            ForEach(places) { place in
                Button {
                    onSelect(place)
                } label: {
                    HStack {
                        Text(place.displayName)
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
                            onDelete(place)
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
