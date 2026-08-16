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
    private let thumbnailDataLoader: @Sendable (URL) throws -> Data?
    private var activeLoads: Int = 0
    private var waitingRequests: [UUID: ThumbnailWaiter] = [:]
    private var waitingOrder: [UUID] = []
    private var cache: [ThumbnailCacheKey: NSImage] = [:]

    init(
        maximumConcurrentLoads: Int = 4,
        thumbnailDataLoader: @escaping @Sendable (URL) throws -> Data? = { modelURL in
            let service = ModelThumbnailService()
            return try service.thumbnailData(for: modelURL)
        }
    ) {
        self.maximumConcurrentLoads = maximumConcurrentLoads
        self.thumbnailDataLoader = thumbnailDataLoader
    }

    func waitingLoadCount() -> Int {
        return waitingRequests.count
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

        try await waitForAvailableSlot()

        defer {
            releaseSlot()
        }

        try Task.checkCancellation()

        if let cachedImage = cache[cacheKey] {
            return ThumbnailLoadResult.loaded(cachedImage)
        }

        let thumbnailDataLoader = self.thumbnailDataLoader

        let loadingTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()

            let thumbnailData = try thumbnailDataLoader(
                modelURL
            )

            try Task.checkCancellation()

            guard let thumbnailData else {
                return ThumbnailLoadResult.noThumbnail
            }

            guard let image = NSImage(data: thumbnailData) else {
                return ThumbnailLoadResult.error
            }

            try Task.checkCancellation()

            guard let resizedImage = Self.resize(
                image,
                to: size
            ) else {
                return ThumbnailLoadResult.error
            }

            try Task.checkCancellation()

            return ThumbnailLoadResult.loaded(resizedImage)
        }

        let result = try await withTaskCancellationHandler(
            operation: {
                try await loadingTask.value
            },
            onCancel: {
                loadingTask.cancel()
            }
        )

        try Task.checkCancellation()

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

    private func waitForAvailableSlot() async throws {
        if activeLoads < maximumConcurrentLoads {
            activeLoads += 1
            return
        }

        let requestID = UUID()
        let waiter = ThumbnailWaiter()

        waitingRequests[requestID] = waiter
        waitingOrder.append(requestID)

        await withTaskCancellationHandler(
            operation: {
                await waiter.wait()
            },
            onCancel: {
                Task {
                    await self.cancelWaitingRequest(
                        requestID: requestID
                    )
                }
            }
        )

        try Task.checkCancellation()

        activeLoads += 1
    }

    private func cancelWaitingRequest(
        requestID: UUID
    ) {
        guard let waiter = waitingRequests.removeValue(
            forKey: requestID
        ) else {
            return
        }

        waitingOrder.removeAll {
            $0 == requestID
        }

        waiter.cancel()
    }

    private func releaseSlot() {
        activeLoads -= 1

        while !waitingOrder.isEmpty {
            let requestID = waitingOrder.removeFirst()

            guard let waiter = waitingRequests.removeValue(
                forKey: requestID
            ) else {
                continue
            }

            waiter.resume()
            return
        }
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

private final class ThumbnailWaiter: @unchecked Sendable {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        var capturedContinuation: AsyncStream<Void>.Continuation?

        self.stream = AsyncStream<Void> { continuation in
            capturedContinuation = continuation
        }

        self.continuation = capturedContinuation!
    }

    func wait() async {
        for await _ in stream {
            return
        }
    }

    func resume() {
        continuation.yield(())
        continuation.finish()
    }

    func cancel() {
        continuation.finish()
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
