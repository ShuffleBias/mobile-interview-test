import SwiftUI

struct HotelRowView: View {
    let hotel: Hotel
    var currencySymbol: String = "$"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroSection
            infoSection
            Divider()
                .padding(.horizontal, Design.Spacing.md)
        }
        .background(Color.rpCard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Hero (full-width image + gradient overlay)

    private var heroSection: some View {
        CachedAsyncImage(
            url: hotel.primaryImageURL,
            content: { image in
                image
                    .resizable()
                    .aspectRatio(3 / 2, contentMode: .fill)
            },
            placeholder: {
                Rectangle()
                    .fill(Color.rpSurface)
                    .aspectRatio(3 / 2, contentMode: .fill)
                    .overlay(
                        ProgressView()
                            .tint(Color.rpBrandMid)
                    )
            },
            failure: {
                Rectangle()
                    .fill(Color.rpSurface)
                    .aspectRatio(3 / 2, contentMode: .fill)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(Color.rpTertiaryText)
                    )
            }
        )
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: .bottom) {
            bottomGradientOverlay
        }
        .accessibilityHidden(true)
    }

    private var bottomGradientOverlay: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.50)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let badges = vibeBadges, !badges.isEmpty {
                HStack(spacing: Design.Spacing.xs) {
                    ForEach(badges, id: \.self) { badge in
                        Text(badge)
                            .font(Design.Typography.badge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Design.Spacing.sm)
                            .padding(.vertical, Design.Spacing.xs)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
                .padding(Design.Spacing.sm)
            }
        }
    }

    // MARK: - Info section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            nameRow
            ratingRow
            productRow
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.top, Design.Spacing.sm)
        .padding(.bottom, Design.Spacing.md)
    }

    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.xs) {
            Text(hotel.name)
                .font(Design.Typography.headline)
                .foregroundStyle(Color.rpPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Design.Spacing.xs)

            if let stars = hotel.hotelStar {
                starBadge(stars)
            }
        }
    }

    private var ratingRow: some View {
        HStack(spacing: Design.Spacing.xs) {
            if let rating = hotel.rating, rating > 0 {
                ratingStars(rating: rating)
                Text(String(format: "%.1f", rating))
                    .font(Design.Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.rpPrimaryText)
            }
            if let reviews = hotel.reviews, reviews > 0 {
                Text("(\(reviews))")
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.rpSecondaryText)
            }
            Spacer()
            if let distance = hotel.distanceText, !distance.isEmpty {
                Text(distance)
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.rpSecondaryText)
            }
        }
    }

    private var productRow: some View {
        Group {
            if let product = hotel.featuredProduct {
                HStack(spacing: Design.Spacing.xs) {
                    if let name = product.name {
                        Text(name)
                            .font(Design.Typography.subheadline)
                            .foregroundStyle(Color.rpSecondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    if let price = product.price {
                        Text("from \(currencySymbol)\(Int(price))")
                            .font(Design.Typography.price)
                            .foregroundStyle(Color.rpBrand)
                    }
                }
            } else if let productName = hotel.productName {
                Text(productName)
                    .font(Design.Typography.subheadline)
                    .foregroundStyle(Color.rpSecondaryText)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Helpers

    private var vibeBadges: [String]? {
        var tags: [String] = []
        if let primary = hotel.vibes?.primary { tags.append(primary) }
        if let secondary = hotel.vibes?.secondary { tags.append(secondary) }
        if let categories = hotel.productCategories?.prefix(1) { tags += categories }
        return tags.isEmpty ? nil : Array(tags.prefix(3))
    }

    private func starBadge(_ count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.rpStarFilled)
            Text("\(count)")
                .font(Design.Typography.badge)
                .foregroundStyle(Color.rpPrimaryText)
        }
        .padding(.horizontal, Design.Spacing.sm)
        .padding(.vertical, 3)
        .background(Color.rpStarFilled.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func ratingStars(rating: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(Double(index) <= rating ? Color.rpStarFilled : Color.rpTertiaryText)
            }
        }
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        var parts = [hotel.name]
        if let rating = hotel.rating, rating > 0 {
            parts.append(String(format: "Rated %.1f out of 5", rating))
        }
        if let reviews = hotel.reviews {
            parts.append("\(reviews) reviews")
        }
        if let product = hotel.featuredProduct {
            if let name = product.name, let price = product.price {
                parts.append("\(name), from \(currencySymbol)\(Int(price))")
            }
        }
        return parts.joined(separator: ". ")
    }
}
