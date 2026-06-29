# ResortPass iOS – Take-Home Interview Project

A native iOS app built with SwiftUI for the ResortPass Founding iOS Engineer interview. It implements two interconnected screens: an autocomplete search that suggests destinations as you type, and a hotel listing screen that loads hotels near the selected destination.

---

## Getting Started

Requirements: Xcode 16+ (Xcode 26 recommended), Swift 6, Homebrew.

```bash
git clone https://github.com/ShuffleBias/mobile-interview-test
cd mobile-interview-test
brew install xcodegen
xcodegen generate
open ResortPassInterview.xcodeproj
```

Build and run on the **iPhone 16** (or later) simulator. No additional setup required — SPM resolves dependencies automatically on first build.

---

## Architecture

The codebase follows **Clean Architecture** with three distinct layers:

```
Presentation  →  Domain  →  Data
Views + VMs      Models      Network
                 Services
```

Dependencies only point inward — views know nothing about network clients, and every boundary is a protocol, so swapping implementations (live → mock) requires no changes to the layers above.

### Layers at a glance

| Layer | What lives here |
|---|---|
| **Presentation** | SwiftUI views, `@Observable` ViewModels, navigation router, shared UI components |
| **Domain** | `Codable` model types (`Place`, `Hotel`), service protocols (`SearchServiceProtocol`, `HotelServiceProtocol`) |
| **Data** | `URLSessionNetworkClient`, `LiveSearchService`, `LiveHotelService` |
| **DesignSystem** | `DesignTokens` (spacing, typography, semantic colors), reusable view modifiers |

### State machine

Every screen is driven by a typed `ViewState<T>` enum:

```swift
enum ViewState<T> {
    case idle       // nothing has happened yet (search only)
    case loading    // request in flight
    case success(T) // data arrived
    case empty      // request succeeded but returned nothing
    case error(any Error) // request failed
}
```

`ViewStateContainer` is a generic SwiftUI view that switches on this enum, rendering the correct child — including a retry button on `.error` — so each screen's body stays declarative and state-handling logic lives in one place.

---

## Key Design Decisions

### `@Observable` MVVM — why iOS 17 and not 16

The deployment target is **iOS 17.0** rather than the minimum-allowed iOS 16. In mid-2026 iOS 17 is two major versions old, and carrying iOS 16 compatibility would mean giving up `@Observable` — the modern replacement for `ObservableObject` — and losing full Swift 6 strict concurrency checking. The install base math makes it a clear call.

ViewModels are `@Observable @MainActor final class`, which gives:
- Automatic UI updates without `@Published` on every property
- Compile-time strict concurrency safety on the main actor
- Easy protocol-based mocking for unit tests (no SwiftUI scaffolding required)

### Pure Swift Concurrency debounce — no Combine

The autocomplete debounces at 500 ms using a `Task` + `Task.sleep` pattern:

```swift
searchTask?.cancel()
searchTask = Task {
    try? await Task.sleep(for: .milliseconds(500))
    guard !Task.isCancelled else { return }
    await performSearch(query: text)
}
```

This avoids importing Combine solely for `.debounce`. It is idiomatic Swift 6, composes naturally with `async/await`, and keeps all async work in a single mental model. The `try?` silently absorbs `CancellationError` from the sleep; the `Task.isCancelled` guard prevents a stale request from reaching the network after the user has already moved on.

### NavigationStack + typed `AppDestination` enum

```swift
enum AppDestination: Hashable {
    case hotelList(Place)
}
```

`NavigationStack(path:)` with a typed destination enum gives compile-time exhaustiveness on the `navigationDestination` switch — a missing handler is a build error, not a silent no-op. Deep links decode into the same cases, so the routing logic stays in one place.

A coordinator object would be the right call if navigation needed to be driven from outside the view hierarchy (push notification handlers, auth state changes that need to reset the stack), but for a two-screen linear flow it's unnecessary indirection. If the app grew to eight or ten screens, or needed cross-feature navigation, revisiting that decision would make sense.

### Dependency injection via constructor + `@Environment`

`AppDependencies` is a plain `Sendable` struct constructed once at the `App` entry point. The strategy is two-level: the environment carries the container down the view tree (avoiding threading it through every initializer), but ViewModels receive services through constructor injection rather than reading from the environment themselves. That distinction matters — a ViewModel that pulls its own dependencies from the environment is coupled to SwiftUI and can't be tested without a hosting view. One that takes a `SearchServiceable` in its initializer can be tested with a plain mock in a regular `@Test` function.

No DI container (Factory, Swinject, etc.) was reached for. With two services, the registration and resolution ceremony costs more than it saves. At five or six services, or once per-feature scopes are needed, a container starts earning its place.

### Networking: `URLSession` directly

Two endpoints don't justify an Alamofire dependency. `URLSessionNetworkClient` is a thin, protocol-backed wrapper around `URLSession.data(for:)` with structured error mapping (`NetworkError`). The `JSONDecoder` is configured once with `keyDecodingStrategy = .convertFromSnakeCase`, so model types use camelCase throughout without manual `CodingKeys`.

### Image caching: native two-tier cache (zero dependencies)

`ImageCache` is a ~80-line platform-native implementation:
- **Tier 1 (memory):** `NSCache<NSURL, UIImage>` — thread-safe, auto-evicts under memory pressure, 50 MB / 150 image limit
- **Tier 2 (disk):** `DiskCache` actor — `FileManager` writes to `caches/com.resortpass.imagecache/`, filenames are `SHA256(url)` hex strings via `CryptoKit` (no path-length or special-character issues)

A cache hit at tier 1 returns synchronously with no context switch. A tier 2 hit decodes the image, promotes it to memory, then returns. A miss fetches with `URLSession.shared.data(from:)` and populates both tiers. `CachedAsyncImage` is the SwiftUI view; `.task(id: url)` handles cancellation automatically when the URL changes or the row scrolls out.

Using `@unchecked Sendable` on `ImageCache` is correct — `NSCache` is documented as thread-safe by Apple, and all disk operations are isolated to the `DiskCache` actor.

Nuke would add progressive JPEG decoding, request deduplication, and priority queuing — none of which are needed at this scale — so keeping zero production dependencies was the easier call.

### Skeleton loading for the hotel list

The hotel list shows shimmer placeholder rows during the `.loading` state rather than a full-screen `ProgressView`. The skeleton mirrors `HotelRowView`'s structure exactly — same 3:2 hero block, same info-section layout (name bar, rating bar, price bar) — so there's no layout shift when content arrives.

`ShimmerModifier` is about 30 lines of vanilla SwiftUI: a `LinearGradient` with `.blendMode(.screen)` sweeps left-to-right via a `withAnimation(.repeatForever)` on a `@State` phase variable. The gradient is off-screen at both ends of the cycle, so the loop restarts seamlessly. No third-party library needed.

`HotelListView` handles the `.loading` case directly rather than routing through `ViewStateContainer`, since the skeleton replaces the generic spinner. The other states (empty, error, retry) still use `ViewStateContainer`.

### XcodeGen for project generation

The `.xcodeproj` is generated from `project.yml` via XcodeGen. This keeps the project definition human-readable, eliminates `.pbxproj` merge conflicts, and means reviewers can see exactly what the project contains without opening Xcode. Regenerating after any structural change is one command: `xcodegen generate`.

---

## Project Structure

```
ResortPassInterview/
├── ResortPassInterviewApp.swift      # App entry point, DI wiring, @State singletons
├── AppDependencies.swift             # Network service container + EnvironmentKey
├── Core/
│   ├── Network/
│   │   ├── NetworkClient.swift       # Protocol + URLSession implementation
│   │   ├── Endpoint.swift            # Typed URL builder (GET / POST with body)
│   │   └── NetworkError.swift        # Typed error enum
│   ├── ImageCache/
│   │   └── ImageCache.swift          # Two-tier cache: NSCache + DiskCache actor (CryptoKit)
│   └── NetworkMonitor.swift          # NWPathMonitor wrapper (@Observable, @MainActor)
├── Domain/
│   ├── Models/
│   │   ├── Place.swift               # Autocomplete result (Codable)
│   │   └── Hotel.swift               # Hotel + nested types + HotelPage (Codable)
│   ├── Services/
│   │   ├── SearchService.swift       # Protocol + live implementation
│   │   └── HotelService.swift        # Protocol + HotelPage pagination support
│   └── SearchHistoryStore.swift      # @Observable UserDefaults-backed recent searches
├── Presentation/
│   ├── Navigation/
│   │   └── AppRouter.swift           # NavigationStack + typed destinations + offline overlay
│   ├── Search/
│   │   ├── SearchViewModel.swift     # @Observable, 500ms debounce, Task cancellation
│   │   ├── SearchView.swift          # Search bar + results + recent history
│   │   ├── SearchHistoryView.swift   # Recent searches list with swipe-to-delete
│   │   └── PlaceRowView.swift        # Single autocomplete row
│   ├── Hotels/
│   │   ├── HotelListViewModel.swift  # @Observable, load/retry/pagination
│   │   ├── HotelListView.swift       # Skeleton loading → LazyVStack + infinite scroll
│   │   ├── HotelRowView.swift        # CachedAsyncImage, star rating, product price
│   │   └── HotelSkeletonRowView.swift # Shimmer placeholder — mirrors HotelRowView layout
│   └── Components/
│       ├── ViewStateContainer.swift  # Generic view that switches on ViewState<T>
│       ├── CachedAsyncImage.swift    # SwiftUI image view backed by ImageCache
│       ├── EmptyStateView.swift      # SF Symbol + title + message
│       ├── ErrorStateView.swift      # Error message + retry button
│       ├── OfflineBannerView.swift   # Animated offline indicator
│       └── ShimmerModifier.swift     # Left-to-right highlight sweep — View.shimmer()
└── DesignSystem/
    └── Design.swift                  # Spacing, typography, semantic Color extensions, view modifiers

ResortPassInterviewTests/
├── Mocks.swift                       # MockSearchService, MockHotelService, fixtures
├── SearchViewModelTests.swift        # 8 tests: debounce, cancellation, all states
├── HotelListViewModelTests.swift     # 7 tests: load, retry, empty, error, pagination
├── NetworkClientTests.swift          # 4 tests via URLProtocol stubbing
└── Snapshots/
    ├── HotelRowViewSnapshotTests.swift   # light + dark mode
    ├── PlaceRowViewSnapshotTests.swift   # light + dark mode
    └── ComponentSnapshotTests.swift      # EmptyState, ErrorState, OfflineBanner
```

**Total: 27 tests (20 unit + 7 snapshot)**

---

## Known Limitations

- **No offline data cache** — search results and hotel listings are not persisted between sessions. A `SwiftData` store would improve perceived performance on repeat visits. (Images are cached across sessions via the disk tier of `ImageCache`.)
- **No error logging** — production code would route `NetworkError` to a crash reporter and fire analytics events on key interactions.
- **Staging only** — `Endpoint.baseURL` is hardcoded to `staging-app.resortpass.com`. A real build would select the URL via build configuration (e.g. `xcconfig` per scheme).
- **Pagination error recovery** — a failure mid-scroll is silently swallowed to preserve the already-loaded list; adding a toast or retry affordance at the bottom would improve UX.
- **Dynamic Type** — `Design.Typography` uses fixed point sizes. To fully support Dynamic Type (user font-size preference), each entry would be replaced with a `UIFontMetrics(forTextStyle:).scaledValue(for:)` call, or `@ScaledMetric(relativeTo:)` would be applied per call-site. The single-file design system structure makes this a straightforward future migration.

## With more time I would…

- Extract `Core/Network/` into a standalone Swift package shared across apps. ResortPass likely has more than one client (iOS consumer app, partner/hotel portal, etc.) and they'd all hit the same staging/production APIs — the `Endpoint` builder, `URLSessionNetworkClient`, and `NetworkError` types are generic enough to live in a shared internal library rather than being copy-pasted per project.
- Extract a per-feature DI scope once the feature count grows beyond two screens.
- Add `SwiftData` caching so search results are available offline and on cold launch.
- Introduce a CI pipeline (GitHub Actions) that runs `xcodebuild test` and fails on snapshot diffs.
- Scope the dependency injection more granularly per feature module.
