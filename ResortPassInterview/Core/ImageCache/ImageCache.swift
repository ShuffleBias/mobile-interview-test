import UIKit
import CryptoKit

// MARK: - Two-tier image cache (memory + disk)

/// Singleton image cache with a fast in-memory tier (NSCache) and a
/// persistent disk tier (FileManager). Thread-safe: NSCache is internally
/// locked, disk operations are isolated to a dedicated actor.
/// @unchecked Sendable is correct here — NSCache is thread-safe by Apple's guarantee.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let memory: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        cache.countLimit = 150
        return cache
    }()

    private let disk = DiskCache()

    private init() {}

    // MARK: - Public interface

    func image(for url: URL) async -> UIImage? {
        let key = url as NSURL

        // Tier 1 — memory (synchronous, no context switch)
        if let cached = memory.object(forKey: key) {
            return cached
        }

        // Tier 2 — disk
        if let data = await disk.read(url: url), let image = UIImage(data: data) {
            memory.setObject(image, forKey: key, cost: data.count)
            return image
        }

        return nil
    }

    func store(image: UIImage, data: Data, for url: URL) async {
        memory.setObject(image, forKey: url as NSURL, cost: data.count)
        await disk.write(data, url: url)
    }
}

// MARK: - Disk tier

/// Actor-isolated disk cache. Each URL maps to a deterministic filename
/// derived from a SHA-256 hash of the URL string, avoiding path-length
/// and special-character issues.
private actor DiskCache {
    private let directory: URL
    private let fileManager = FileManager.default

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("com.resortpass.imagecache")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func read(url: URL) -> Data? {
        try? Data(contentsOf: path(for: url))
    }

    func write(_ data: Data, url: URL) {
        try? data.write(to: path(for: url), options: .atomic)
    }

    private func path(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(hex)
    }
}
