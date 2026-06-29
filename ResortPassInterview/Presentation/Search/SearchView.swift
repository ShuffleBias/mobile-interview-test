import SwiftUI

struct SearchView: View {
    @State var viewModel: SearchViewModel
    let onSelectPlace: (Place) -> Void

    @Environment(SearchHistoryStore.self) private var searchHistory

    var body: some View {
        VStack(spacing: 0) {
            brandedHeader
            bodyContent
        }
        .background(Color.rpBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Branded gradient header

    private var brandedHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.rpBrand, Color.rpBrandMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                Text("Discover")
                    .font(Design.Typography.displayTitle)
                    .foregroundStyle(.white)
                    .padding(.top, Design.Spacing.md)

                Text("Find resorts & day passes near you")
                    .font(Design.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.80))

                searchBar
                    .padding(.bottom, Design.Spacing.md)
            }
            .padding(.horizontal, Design.Spacing.md)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchBar: some View {
        HStack(spacing: Design.Spacing.sm) {
            Group {
                if case .loading = viewModel.state {
                    ProgressView()
                        .tint(Color.rpBrand)
                        .transition(.opacity)
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.rpBrandMid)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .frame(width: 20)
            .accessibilityHidden(true)

            TextField("Search destinations...", text: $viewModel.searchText)
                .font(Design.Typography.body)
                .foregroundStyle(Color.rpPrimaryText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onChange(of: viewModel.searchText) { _, newValue in
                    viewModel.onSearchTextChanged(newValue)
                }
                .accessibilityLabel("Search destinations")

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.onSearchTextChanged("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.rpTertiaryText)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.searchText.isEmpty)
        .padding(.horizontal, Design.Spacing.md)
        .padding(.vertical, Design.Spacing.sm + 2)
        .background(Color.rpCard)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
    }

    // MARK: - Body content

    @ViewBuilder
    private var bodyContent: some View {
        if case .idle = viewModel.state, viewModel.searchText.isEmpty, !searchHistory.queries.isEmpty {
            SearchHistoryView(store: searchHistory) { query in
                viewModel.searchText = query
                viewModel.onSearchTextChanged(query)
            }
        } else {
            ViewStateContainer(
                state: viewModel.state,
                content: { places in
                    List(places) { place in
                        Button {
                            searchHistory.add(viewModel.searchText)
                            onSelectPlace(place)
                        } label: {
                            PlaceRowView(place: place)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.rpBackground)
                        .listRowSeparatorTint(Color.rpSurface)
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)
                },
                emptyView: {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Results",
                        message: "No destinations match \"\(viewModel.searchText)\". Try a different search."
                    )
                },
                onRetry: { viewModel.retry() }
            )
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}
