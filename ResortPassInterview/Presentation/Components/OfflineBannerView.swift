import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .accessibilityHidden(true)
            Text("No Internet Connection")
                .font(Design.Typography.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.sm)
        .padding(.horizontal, Design.Spacing.md)
        .background(Color.orange)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No internet connection")
        .accessibilityAddTraits(.isStaticText)
    }
}
