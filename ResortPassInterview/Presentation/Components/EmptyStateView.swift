import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(Color.rpBrandMid)
                .accessibilityHidden(true)

            Text(title)
                .font(Design.Typography.title)
                .foregroundStyle(Color.rpPrimaryText)

            Text(message)
                .font(Design.Typography.body)
                .foregroundStyle(Color.rpSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Design.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
