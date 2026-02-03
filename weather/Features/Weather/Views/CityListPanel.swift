//
//  CityListPanel.swift
//  weather
//

import SwiftUI

struct CityListPanel: View {
    enum Style {
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

            rows
        }
        // When we use `List` (swipe-to-delete), we should avoid wrapping it in a "card".
        // Keeping it unwrapped makes it feel more native and prevents heavy visual separation.
        .modifier(PanelBackground(style: style, enabled: onDelete == nil))
    }

    private var rows: some View {
        Group {
            if onDelete != nil {
                swipeListRows
            } else if cities.count > scrollThreshold {
                ScrollView {
                    plainRows
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: maxHeight)
            } else {
                plainRows
            }
        }
    }

    private var plainRows: some View {
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

    private var swipeListRows: some View {
        // Use List so we can get native swipe-to-delete behavior, with smooth animations
        // and proper scroll interaction.
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
                    Button(role: .destructive) {
                        onDelete?(name)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxHeight: maxHeight)
    }
}

private struct PanelBackground: ViewModifier {
    let style: CityListPanel.Style
    let enabled: Bool

    func body(content: Content) -> some View {
        guard enabled else { return AnyView(content) }

        switch style {
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
