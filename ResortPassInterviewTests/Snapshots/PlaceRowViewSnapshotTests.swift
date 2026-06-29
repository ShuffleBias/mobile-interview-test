import XCTest
import SwiftUI
import SnapshotTesting
@testable import ResortPassInterview

@MainActor
final class PlaceRowViewSnapshotTests: XCTestCase {
    private let place = Place.fixture(name: "New York City")

    func test_placeRowView_light() {
        let view = PlaceRowView(place: place)
            .frame(width: 375)
            .padding(.horizontal)
            .environment(\.colorScheme, .light)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe),
            named: "light"
        )
    }

    func test_placeRowView_dark() {
        let view = PlaceRowView(place: place)
            .frame(width: 375)
            .padding(.horizontal)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe),
            named: "dark"
        )
    }
}
