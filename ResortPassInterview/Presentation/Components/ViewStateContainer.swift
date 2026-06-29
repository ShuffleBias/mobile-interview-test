import SwiftUI

/// Generic view that renders the appropriate UI for each phase of an async data load.
enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case empty
    case error(any Error)
}

struct ViewStateContainer<T: Sendable, Content: View, Empty: View>: View {
    let state: ViewState<T>
    @ViewBuilder let content: (T) -> Content
    @ViewBuilder let emptyView: () -> Empty
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            Color.clear

        case .loading:
            ProgressView()
                .tint(Color.rpBrand)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading")

        case .success(let value):
            content(value)

        case .empty:
            emptyView()

        case .error(let error):
            ErrorStateView(message: error.localizedDescription, onRetry: onRetry)
        }
    }
}
