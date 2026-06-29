// Single source of truth for spacing, typography, colors, and corner radii.
// Views never hard-code pixel values or hex strings — everything routes through here.

import SwiftUI

// MARK: - Design

enum Design {

    // MARK: - Spacing (8-pt grid)
    //
    //   xs   4 pt — icon-to-label, star gaps
    //   sm   8 pt — badge padding, tight rows
    //   md  16 pt — screen edges, card padding
    //   lg  24 pt — between card sections
    //   xl  32 pt — empty-state illustration padding
    //   xxl 48 pt — decorative vertical rhythm

    enum Spacing {
        /// 4 pt — use for very tight gaps: icon-to-text, star-to-star.
        static let xs: CGFloat = 4

        /// 8 pt — comfortable small gap: rating row, badge padding.
        static let sm: CGFloat = 8

        /// 16 pt — default screen edge and card padding.
        static let md: CGFloat = 16

        /// 24 pt — between distinct sections.
        static let lg: CGFloat = 24

        /// 32 pt — empty-state illustration padding.
        static let xl: CGFloat = 32

        /// 48 pt — large decorative vertical spacing.
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        /// 6 pt — icon badge wells, small chips.
        static let small: CGFloat = 6

        /// 12 pt — cards, sheets, search bar.
        static let card: CGFloat = 12

        /// 999 pt — use for capsule / pill shapes (buttons, tags).
        static let pill: CGFloat = 999
    }

    // MARK: - Typography
    //
    // Fixed sizes — Dynamic Type not yet wired. When that work lands,
    // swap each entry for UIFontMetrics(forTextStyle:).scaledValue(for:);
    // keeping sizes here means the migration is one-file.

    enum Typography {
        /// 28 pt Bold — hero headline. Used in the search screen gradient header.
        static let displayTitle: Font = .system(size: 28, weight: .bold)

        /// 18 pt Semibold — screen-level or major section heading.
        static let title: Font = .system(size: 18, weight: .semibold)

        /// 15 pt Semibold — card titles, important label text.
        static let headline: Font = .system(size: 15, weight: .semibold)

        /// 15 pt Regular — body copy, search field text.
        static let body: Font = .system(size: 15, weight: .regular)

        /// 13 pt Regular — secondary descriptive text below a headline.
        static let subheadline: Font = .system(size: 13, weight: .regular)

        /// 12 pt Regular — review counts, distances, meta info.
        static let caption: Font = .system(size: 12, weight: .regular)

        /// 11 pt Semibold — vibe/category pill badges on hotel images.
        static let badge: Font = .system(size: 11, weight: .semibold)

        /// 17 pt Bold, monospaced digits — price display ("from $50").
        /// Monospaced keeps the dollar amounts from jumping when values change.
        static let price: Font = .system(size: 17, weight: .bold).monospacedDigit()
    }

    // MARK: - Shadow
    // One level of elevation. The rpSurface tint already separates
    // cards visually, so the shadow is intentionally very light.

    enum Shadow {
        /// Standard card elevation: very light, tight to the element.
        static let card = CardShadow()
    }

    struct CardShadow {
        /// Shadow color. Keep opacity low — heavy shadows look cheap on light backgrounds.
        let color: Color = .black.opacity(0.06)

        /// Blur radius in points. 4 pt = tight, subtle; 12+ pt = airy, elevated.
        let radius: CGFloat = 4

        /// Horizontal offset. 0 = centered shadow (no directional light source).
        let x: CGFloat = 0

        /// Vertical offset. 1 pt pushes shadow slightly below the element.
        let y: CGFloat = 1
    }
}

// MARK: - Semantic Colors
// All `rp`-prefixed; rebanding the app is a change to this extension only.

extension Color {

    // MARK: Brand — resort-water blue

    /// #1A5FB4 — primary brand blue. Use for primary buttons, links, and key icons.
    static let rpBrand = Color(red: 0.102, green: 0.373, blue: 0.706)

    /// #4A90D9 — mid-tone brand blue. Use for gradients, secondary UI elements.
    static let rpBrandMid = Color(red: 0.290, green: 0.565, blue: 0.851)

    /// Alias for rpBrand. Prefer this name in view code so swapping the accent color
    /// is a single-token change here rather than a grep across the codebase.
    static let rpAccent = Color(red: 0.102, green: 0.373, blue: 0.706)

    // MARK: Surfaces

    /// The app's primary page background — pure white in light mode, system-default in dark.
    static let rpBackground = Color(uiColor: .systemBackground)

    /// Card background — always white/system-background. Sits above rpSurface.
    static let rpCard = Color(uiColor: .systemBackground)

    /// Page tint — light: #EEF4FF (barely-blue white); dark: deep blue-grey.
    /// Used as the ScrollView background so hairline gaps between full-width cards
    /// show this color instead of plain grey, reinforcing the brand palette.
    static let rpSurface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09,  green: 0.12,  blue: 0.18,  alpha: 1) // deep blue-grey
            : UIColor(red: 0.933, green: 0.957, blue: 1.000, alpha: 1) // #EEF4FF very light blue
    })

    // MARK: Text hierarchy

    /// High-contrast text — hotel names, search results, prices. Follows system label color.
    static let rpPrimaryText = Color(uiColor: .label)

    /// Medium-contrast text with a blue-grey tint — subtitles, review counts, distances.
    /// Light mode: #5A708A (muted blue-slate). Dark mode: #8CADD1 (lighter for contrast).
    static let rpSecondaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.68, blue: 0.82, alpha: 1) // #8CADD1 — lighter in dark
            : UIColor(red: 0.35, green: 0.44, blue: 0.54, alpha: 1) // #5A708A — muted blue-slate
    })

    /// Low-contrast text — placeholder text, disabled state, icon fallbacks.
    static let rpTertiaryText = Color(uiColor: .tertiaryLabel)

    // MARK: Decorative

    /// Separator lines between list rows.
    static let rpSeparator = Color(uiColor: .separator)

    /// #FEBB00 — warm yellow for star rating fills. Intentionally warm to contrast the cool blue palette.
    static let rpStarFilled = Color(red: 0.996, green: 0.733, blue: 0.0)

    /// Skeleton placeholder fill — UIColor.systemFill adapts automatically to dark mode.
    static let rpSkeleton = Color(uiColor: .systemFill)
}

// MARK: - View Modifiers

extension View {

    /// Applies the standard card style: white background + subtle bottom shadow.
    /// Cards are full-width (no corner clipping on sides) — the rpSurface background
    /// peeking through 1 pt gaps between cards acts as the visual separator.
    func cardStyle() -> some View {
        self
            .background(Color.rpCard)
            .shadow(
                color: Design.Shadow.card.color,
                radius: Design.Shadow.card.radius,
                x: Design.Shadow.card.x,
                y: Design.Shadow.card.y
            )
    }

    /// Blue-tinted rounded-rect background for icon wells in list rows.
    /// Gives place-type icons (city, map, globe) a subtle brand-blue badge feel
    /// without being as heavy as a filled button.
    func iconBadge() -> some View {
        self
            .padding(8)
            .background(Color.rpAccent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.small))
    }
}
