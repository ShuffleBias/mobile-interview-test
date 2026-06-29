import SwiftUI

/// Placeholder row shown while the hotel list is loading.
///
/// The layout intentionally mirrors `HotelRowView` — same hero aspect ratio,
/// same info-section structure (name bar, rating bar, price bar) — so SwiftUI
/// can cross-fade from skeleton to real content with no layout shift.
struct HotelSkeletonRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroPlaceholder
            infoPlaceholder
            Divider()
                .padding(.horizontal, Design.Spacing.md)
        }
        .background(Color.rpCard)
        .shimmer()
        .accessibilityHidden(true)
    }

    // MARK: - Hero

    private var heroPlaceholder: some View {
        Rectangle()
            .fill(Color.rpSkeleton)
            .aspectRatio(3.0 / 2.0, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    // MARK: - Info

    private var infoPlaceholder: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            // nameRow — hotel name (left) + star badge (right)
            HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.xs) {
                skeletonRect(width: 160, height: 14)
                Spacer(minLength: Design.Spacing.xs)
                skeletonRect(width: 44, height: 20, cornerRadius: Design.Radius.pill)
            }
            // ratingRow — stars + rating (left) + distance (right)
            HStack(spacing: Design.Spacing.xs) {
                skeletonRect(width: 70, height: 10)
                Spacer()
                skeletonRect(width: 46, height: 10)
            }
            // productRow — product name (left) + price (right)
            HStack(spacing: Design.Spacing.xs) {
                skeletonRect(width: 120, height: 12)
                Spacer()
                skeletonRect(width: 68, height: 16)
            }
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.top, Design.Spacing.sm)
        .padding(.bottom, Design.Spacing.md)
    }

    // MARK: - Helpers

    private func skeletonRect(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = Design.Radius.small
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.rpSkeleton)
            .frame(width: width, height: height)
    }
}
