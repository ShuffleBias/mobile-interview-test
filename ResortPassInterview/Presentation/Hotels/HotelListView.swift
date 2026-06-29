import SwiftUI

struct HotelListView: View {
    @State var viewModel: HotelListViewModel
    let title: String

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.rpSurface)
            .task {
                await viewModel.load()
            }
    }

    // MARK: - State routing

    // The `.loading` case is handled directly here (rather than via ViewStateContainer)
    // so skeleton rows can fill the screen instead of a centered spinner.
    // All other states delegate to ViewStateContainer's shared empty/error/retry logic.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            skeletonList
        case .success(let hotels):
            hotelList(hotels)
        case .empty:
            EmptyStateView(
                systemImage: "building.2.slash",
                title: "No Hotels Found",
                message: "There are no available hotels for this destination right now."
            )
        case .error(let error):
            ErrorStateView(message: error.localizedDescription) {
                Task { await viewModel.retry() }
            }
        }
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(0 ..< 6, id: \.self) { _ in
                    HotelSkeletonRowView()
                }
            }
            .padding(.top, Design.Spacing.xs)
        }
        .background(Color.rpSurface)
    }

    // MARK: - Loaded list

    private func hotelList(_ hotels: [Hotel]) -> some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(hotels) { hotel in
                    HotelRowView(hotel: hotel, currencySymbol: viewModel.currencySymbol)
                        .onAppear {
                            if hotel.id == hotels.last?.id {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.rpBrandMid)
                        .frame(maxWidth: .infinity)
                        .padding(Design.Spacing.md)
                        .accessibilityLabel("Loading more hotels")
                }
            }
            .padding(.top, Design.Spacing.xs)
        }
        .background(Color.rpSurface)
        .scrollDismissesKeyboard(.immediately)
    }
}
