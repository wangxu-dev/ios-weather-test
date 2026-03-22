import SwiftUI
import Observation

struct SearchOverlay: View {
    @Bindable var viewModel: HomeViewModel
    var searchFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            WeatherGlassContainer {
                searchFieldRow
            }

            WeatherGlassContainer {
                locationButton
            }

            contentList
            statusHint
        }
    }

    private var searchFieldRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField("搜索城市", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .weatherInteractiveGlass(in: Capsule())
                .focused(searchFieldFocused)

            Button("关闭") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    viewModel.hideSearch()
                }
                searchFieldFocused.wrappedValue = false
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .weatherInteractiveGlass(in: Capsule())
        }
    }

    private var locationButton: some View {
        Button {
            Task { await viewModel.resolveCurrentLocationAndAdd() }
        } label: {
            Label("使用当前位置", systemImage: "location.fill")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .weatherInteractiveGlass(in: RoundedRectangle(cornerRadius: DS.Radius.panel, style: .continuous))
    }

    private var contentList: some View {
        List {
            if !viewModel.suggestions.isEmpty {
                Section("搜索结果") {
                    ForEach(viewModel.suggestions) { place in
                        Button {
                            viewModel.addOrSelect(place: place)
                        } label: {
                            Text(place.displayName)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !viewModel.places.isEmpty {
                Section("已添加") {
                    ForEach(viewModel.places) { place in
                        Button {
                            viewModel.addOrSelect(place: place)
                        } label: {
                            Text(place.displayName)
                                .foregroundStyle(.primary)
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
        .listStyle(.plain)
        .frame(maxHeight: 380)
        .scrollContentBackground(.hidden)
        .background(.clear)
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

    private func hintText(_ value: String) -> some View {
        Text(value)
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
