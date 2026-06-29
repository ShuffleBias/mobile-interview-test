import SwiftUI

/// A SwiftUI view that loads a remote image with two-tier caching (memory + disk).
/// The `.task(id: url)` modifier cancels the in-flight fetch automatically
/// whenever the URL changes or the view disappears.
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var uiImage: UIImage?
    @State private var phase: Phase = .empty

    enum Phase { case empty, loading, success, failure }

    var body: some View {
        Group {
            switch phase {
            case .empty, .loading:
                placeholder()
            case .success:
                if let uiImage {
                    content(Image(uiImage: uiImage))
                } else {
                    failure()
                }
            case .failure:
                failure()
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else { phase = .failure; return }

        // Cache hit — no need to show loading state
        if let cached = await ImageCache.shared.image(for: url) {
            uiImage = cached
            phase = .success
            return
        }

        phase = .loading

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }
            guard let image = UIImage(data: data) else { phase = .failure; return }
            await ImageCache.shared.store(image: image, data: data, for: url)
            uiImage = image
            phase = .success
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failure
        }
    }
}
