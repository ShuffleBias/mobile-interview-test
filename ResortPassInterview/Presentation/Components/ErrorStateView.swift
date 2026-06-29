import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rpBrand)
                .accessibilityHidden(true)

            Text("Something went wrong")
                .font(Design.Typography.title)
                .foregroundStyle(Color.rpPrimaryText)

            Text(message)
                .font(Design.Typography.body)
                .foregroundStyle(Color.rpSecondaryText)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(Design.Typography.headline)
                    .padding(.horizontal, Design.Spacing.lg)
                    .padding(.vertical, Design.Spacing.sm)
                    .background(Color.rpBrand)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry")
            .padding(.top, Design.Spacing.xs)
        }
        .padding(Design.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
