import SwiftUI
import Observation

struct SearchOverlay: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            contentList
            statusHint
        }
    }

    private var contentList: some View {
        List {
            if isQuerying, !viewModel.suggestions.isEmpty {
                Section("搜索结果") {
                    ForEach(viewModel.suggestions) { place in
                        Button {
                            viewModel.addOrSelect(place: place)
                        } label: {
                            placeRow(
                                title: place.displayName,
                                systemImage: "magnifyingglass",
                                trailing: "plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !isQuerying {
                Section("管理城市") {
                    Button {
                        Task { await viewModel.resolveCurrentLocationAndAdd() }
                    } label: {
                        placeRow(
                            title: "使用当前位置",
                            systemImage: "location.fill",
                            trailing: "location.north.line"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if !viewModel.places.isEmpty {
                    Section("已添加") {
                        ForEach(viewModel.places) { place in
                            Button {
                                viewModel.addOrSelect(place: place)
                            } label: {
                                placeRow(
                                    title: place.displayName,
                                    systemImage: place.id == viewModel.selectedPlaceID ? "checkmark.circle.fill" : "circle",
                                    trailing: "chevron.right",
                                    highlightLeading: place.id == viewModel.selectedPlaceID
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.remove(placeID: place.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .headerProminence(.standard)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListRowHeight, 56)
        .environment(\.defaultMinListHeaderHeight, 24)
    }

    @ViewBuilder
    private var statusHint: some View {
        switch viewModel.searchStatus {
        case .empty:
            hintText("无匹配城市")
        case .searching:
            hintText("正在搜索…")
        case .error(let message):
            hintText(message)
        case .idle, .results:
            EmptyView()
        }
    }

    private var isQuerying: Bool {
        !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func hintText(_ value: String) -> some View {
        Text(value)
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.md)
    }

    private func placeRow(
        title: String,
        systemImage: String,
        trailing: String,
        highlightLeading: Bool = false
    ) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(highlightLeading ? .primary : .secondary)
                .frame(width: 18)

            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: trailing)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
