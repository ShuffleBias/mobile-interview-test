import SwiftUI

struct SearchHistoryView: View {
    @Bindable var store: SearchHistoryStore
    let onSelect: (String) -> Void

    var body: some View {
        List {
            Section {
                ForEach(store.queries, id: \.self) { query in
                    Button {
                        onSelect(query)
                    } label: {
                        HStack(spacing: Design.Spacing.md) {
                            Image(systemName: "clock")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.rpBrandMid)
                                .frame(width: 20)
                                .accessibilityHidden(true)

                            Text(query)
                                .font(Design.Typography.body)
                                .foregroundStyle(Color.rpPrimaryText)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search for \(query)")
                    .listRowBackground(Color.rpBackground)
                    .listRowSeparatorTint(Color.rpSurface)
                }
                .onDelete { offsets in
                    store.remove(at: offsets)
                }
            } header: {
                HStack {
                    Text("Recent Searches")
                        .font(Design.Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.rpBrand)
                        .textCase(nil)

                    Spacer()

                    Button("Clear All") {
                        store.clear()
                    }
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.rpBrand)
                    .accessibilityLabel("Clear all recent searches")
                }
            }
        }
        .listStyle(.plain)
    }
}
