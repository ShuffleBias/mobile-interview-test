import XCTest
import SwiftUI
import SnapshotTesting
@testable import ResortPassInterview

@MainActor
final class HotelRowViewSnapshotTests: XCTestCase {
    private let hotel = Hotel.fixture(id: 1, name: "TWA Hotel")

    func test_hotelRowView_light() {
        let view = HotelRowView(hotel: hotel, currencySymbol: "$")
            .frame(width: 375)
            .environment(\.colorScheme, .light)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe),
            named: "light"
        )
    }

    func test_hotelRowView_dark() {
        let view = HotelRowView(hotel: hotel, currencySymbol: "$")
            .frame(width: 375)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhoneSe),
            named: "dark"
        )
    }
}
