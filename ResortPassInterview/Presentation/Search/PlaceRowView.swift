import SwiftUI

struct PlaceRowView: View {
    let place: Place

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: iconName(for: place.type))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.rpAccent)
                .iconBadge()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(place.name)
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.rpPrimaryText)

                if let subtitle = subtitle(for: place) {
                    Text(subtitle)
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.rpSecondaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.rpBrandMid.opacity(0.6))
                .accessibilityHidden(true)
        }
        .padding(.vertical, Design.Spacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: place))
        .accessibilityHint("Tap to see hotels")
    }

    // MARK: - Helpers

    private func iconName(for type: String) -> String {
        switch type.lowercased() {
        case "city":         return "building.2"
        case "state":        return "map"
        case "country":      return "globe"
        case "neighborhood": return "mappin.circle"
        default:             return "location"
        }
    }

    private func subtitle(for place: Place) -> String? {
        var parts: [String] = []
        if let city = place.cityName, city != place.name { parts.append(city) }
        if let state = place.stateCode { parts.append(state) }
        if let country = place.countryCode { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func accessibilityLabel(for place: Place) -> String {
        var label = place.name
        if let sub = subtitle(for: place) { label += ", \(sub)" }
        return label
    }
}
