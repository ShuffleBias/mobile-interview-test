import XCTest
import SwiftUI
import SnapshotTesting
@testable import ResortPassInterview

@MainActor
final class ComponentSnapshotTests: XCTestCase {

    func test_emptyStateView() {
        let view = EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Results",
            message: "No destinations match your search."
        )
        .frame(width: 375, height: 400)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe)
        )
    }

    func test_errorStateView() {
        let view = ErrorStateView(
            message: "The server returned an error (HTTP 500).",
            onRetry: {}
        )
        .frame(width: 375, height: 400)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe)
        )
    }

    func test_offlineBannerView() {
        let view = OfflineBannerView()
            .frame(width: 375)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe)
        )
    }
}
