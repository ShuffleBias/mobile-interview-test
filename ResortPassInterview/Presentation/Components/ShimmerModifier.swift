import SwiftUI

extension View {
    /// Sweeps a highlight gradient left-to-right over the view.
    /// Apply to skeleton placeholder rows — no third-party dependency required.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    // Starts off the left edge (-0.5) and sweeps to the right edge (1.5),
    // so the bright band is off-screen at both ends of the cycle and the
    // loop restarts seamlessly with no visible jump.
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.55), .clear],
                    startPoint: UnitPoint(x: phase - 0.25, y: 0.5),
                    endPoint:   UnitPoint(x: phase + 0.25, y: 0.5)
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}
