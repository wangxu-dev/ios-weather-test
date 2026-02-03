//
//  CityListPanel.swift
//  weather
//

import SwiftUI

struct CityListPanel: View {
    enum Style {
        case none
        case plain
        case glass
    }

    let title: String?
    let cities: [String]
    let maxHeight: CGFloat
    let scrollThreshold: Int
    let style: Style
    let onSelect: (String) -> Void
    let onDelete: ((String) -> Void)?

    init(
        title: String? = nil,
        cities: [String],
        maxHeight: CGFloat = 260,
        scrollThreshold: Int = 6,
        style: Style = .glass,
        onSelect: @escaping (String) -> Void,
        onDelete: ((String) -> Void)? = nil
    ) {
        self.title = title
        self.cities = cities
        self.maxHeight = maxHeight
        self.scrollThreshold = scrollThreshold
        self.style = style
        self.onSelect = onSelect
        self.onDelete = onDelete
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

            // Use `List` for both suggestions and added-cities so they feel consistent,
            // scroll smoothly, and support native swipe actions when enabled.
            List {
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
                        if let onDelete {
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
        .modifier(PanelBackground(style: style))
    }
}

private struct PanelBackground: ViewModifier {
    let style: CityListPanel.Style

    func body(content: Content) -> some View {
        switch style {
        case .none:
            return AnyView(content)
        case .glass:
            return AnyView(
                content
                    .glassEffect(in: .rect(cornerRadius: 16))
            )
        case .plain:
            return AnyView(
                content
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground).opacity(0.82))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
                    )
            )
        }
    }
}
