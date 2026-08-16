//
//  ThumbnailLoader.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Coordinates thumbnail loading with a limited number of
//  simultaneous loads and caches resized thumbnails.
//
//  ModelThumbnailService remains responsible for reading
//  thumbnail data from .io files.
//

import Foundation
import AppKit

actor ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let maximumConcurrentLoads: Int
    private var activeLoads: Int = 0
    private var waitingContinuations: [CheckedContinuation<Void, Never>] = []
    private var cache: [ThumbnailCacheKey: NSImage] = [:]

    init(maximumConcurrentLoads: Int = 4) {
        self.maximumConcurrentLoads = maximumConcurrentLoads
    }

    func load(
        for modelURL: URL,
        size: CGSize
    ) async throws -> ThumbnailLoadResult {
        let cacheKey = try thumbnailCacheKey(
            for: modelURL,
            size: size
        )

        if let cachedImage = cache[cacheKey] {
            return ThumbnailLoadResult.loaded(cachedImage)
        }

        await waitForAvailableSlot()

        defer {
            releaseSlot()
        }

        try Task.checkCancellation()

        if let cachedImage = cache[cacheKey] {
            return ThumbnailLoadResult.loaded(cachedImage)
        }

        let service = ModelThumbnailService()

        let result = try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()

            let thumbnailData = try service.thumbnailData(
                for: modelURL
            )

            guard let thumbnailData else {
                return ThumbnailLoadResult.noThumbnail
            }

            guard let image = NSImage(data: thumbnailData) else {
                return ThumbnailLoadResult.error
            }

            guard let resizedImage = Self.resize(
                image,
                to: size
            ) else {
                return ThumbnailLoadResult.error
            }

            return ThumbnailLoadResult.loaded(resizedImage)
        }.value

        if case .loaded(let image) = result {
            cache[cacheKey] = image
        }

        return result
    }

    private func thumbnailCacheKey(
        for modelURL: URL,
        size: CGSize
    ) throws -> ThumbnailCacheKey {
        let attributes = try FileManager.default.attributesOfItem(
            atPath: modelURL.path
        )

        let modificationDate = attributes[
            .modificationDate
        ] as? Date

        return ThumbnailCacheKey(
            url: modelURL.standardizedFileURL,
            modificationDate: modificationDate,
            width: size.width,
            height: size.height
        )
    }

    private func waitForAvailableSlot() async {
        if activeLoads < maximumConcurrentLoads {
            activeLoads += 1
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            waitingContinuations.append(continuation)
        }

        activeLoads += 1
    }

    private func releaseSlot() {
        activeLoads -= 1

        guard !waitingContinuations.isEmpty else {
            return
        }

        let continuation = waitingContinuations.removeFirst()
        continuation.resume()
    }

    private static func resize(
        _ image: NSImage,
        to size: CGSize
    ) -> NSImage? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let resizedImage = NSImage(size: size)

        resizedImage.lockFocus()

        defer {
            resizedImage.unlockFocus()
        }

        image.draw(
            in: NSRect(
                origin: .zero,
                size: size
            ),
            from: NSRect(
                origin: .zero,
                size: image.size
            ),
            operation: .copy,
            fraction: 1.0
        )

        return resizedImage
    }
}

private struct ThumbnailCacheKey: Hashable {
    let url: URL
    let modificationDate: Date?
    let width: CGFloat
    let height: CGFloat
}

enum ThumbnailLoadResult {
    case loaded(NSImage)
    case noThumbnail
    case error
}
