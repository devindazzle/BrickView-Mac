//
//  ThumbnailLoader.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Coordinates thumbnail loading with a limited number of
//  simultaneous loads, priority ordering, and caching of
//  resized thumbnails.
//
//  ModelThumbnailService remains responsible for reading
//  thumbnail data from .io files.
//

import Foundation
import AppKit
import ImageIO
import CoreGraphics

enum ThumbnailPriority {
    case high
    case normal
}

actor ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let maximumConcurrentLoads: Int
    private let thumbnailDataLoader: @Sendable (URL) throws -> Data?
    private var activeLoads: Int = 0
    private var waitingRequests: [UUID: ThumbnailWaiter] = [:]
    private var waitingPriorities: [UUID: ThumbnailPriority] = [:]
    private var waitingOrder: [UUID] = []
    private var cache: [ThumbnailCacheKey: NSImage] = [:]
    private var cgImageCache: [ThumbnailCacheKey: CGImage] = [:]

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
        size: CGSize,
        priority: ThumbnailPriority = .normal
    ) async throws -> ThumbnailLoadResult {
        let cacheKey = try thumbnailCacheKey(
            for: modelURL,
            size: size
        )

        if let cachedImage = cache[cacheKey] {
            return ThumbnailLoadResult.loaded(cachedImage)
        }

        try await waitForAvailableSlot(
            priority: priority
        )

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

    func loadCGImage(
        for modelURL: URL,
        size: CGSize,
        priority: ThumbnailPriority = .normal
    ) async throws -> ThumbnailCGImageLoadResult {
        let cacheKey = try thumbnailCacheKey(
            for: modelURL,
            size: size
        )

        if let cachedImage = cgImageCache[cacheKey] {
            return ThumbnailCGImageLoadResult.loaded(cachedImage)
        }

        try await waitForAvailableSlot(
            priority: priority
        )

        defer {
            releaseSlot()
        }

        try Task.checkCancellation()

        if let cachedImage = cgImageCache[cacheKey] {
            return ThumbnailCGImageLoadResult.loaded(cachedImage)
        }

        let thumbnailDataLoader = self.thumbnailDataLoader

        let loadingTask: Task<ThumbnailCGImageLoadResult, Error> = Task.detached(
            priority: .userInitiated
        ) {
            try Task.checkCancellation()

            guard let thumbnailData = try thumbnailDataLoader(
                modelURL
            ) else {
                return ThumbnailCGImageLoadResult.noThumbnail
            }

            try Task.checkCancellation()

            guard let imageSource = CGImageSourceCreateWithData(
                thumbnailData as CFData,
                nil
            ) else {
                return ThumbnailCGImageLoadResult.error
            }

            guard let image = CGImageSourceCreateImageAtIndex(
                imageSource,
                0,
                nil
            ) else {
                return ThumbnailCGImageLoadResult.error
            }

            try Task.checkCancellation()

            guard let resizedImage = Self.resize(
                image,
                to: size
            ) else {
                return ThumbnailCGImageLoadResult.error
            }

            try Task.checkCancellation()

            return ThumbnailCGImageLoadResult.loaded(
                resizedImage
            )
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
            cgImageCache[cacheKey] = image
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

    private func waitForAvailableSlot(
        priority: ThumbnailPriority
    ) async throws {
        if activeLoads < maximumConcurrentLoads {
            activeLoads += 1
            return
        }

        let requestID = UUID()
        let waiter = ThumbnailWaiter()

        waitingRequests[requestID] = waiter
        waitingPriorities[requestID] = priority
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

        waitingPriorities.removeValue(
            forKey: requestID
        )

        waitingOrder.removeAll {
            $0 == requestID
        }

        waiter.cancel()
    }

    private func releaseSlot() {
        activeLoads -= 1

        guard !waitingOrder.isEmpty else {
            return
        }

        var selectedRequestID: UUID?
        var selectedPriority: ThumbnailPriority?

        for requestID in waitingOrder {
            guard let priority = waitingPriorities[requestID] else {
                continue
            }

            if selectedRequestID == nil {
                selectedRequestID = requestID
                selectedPriority = priority
                continue
            }

            if priorityRank(priority) < priorityRank(selectedPriority!) {
                selectedRequestID = requestID
                selectedPriority = priority
            }
        }

        guard let requestID = selectedRequestID,
              let waiter = waitingRequests.removeValue(
                  forKey: requestID
              ) else {
            return
        }

        waitingPriorities.removeValue(
            forKey: requestID
        )

        waitingOrder.removeAll {
            $0 == requestID
        }

        waiter.resume()
    }

    private func priorityRank(
        _ priority: ThumbnailPriority
    ) -> Int {
        switch priority {
        case .high:
            return 0

        case .normal:
            return 1
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

    private static func resize(
        _ image: CGImage,
        to size: CGSize
    ) -> CGImage? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let width = Int(size.width)
        let height = Int(size.height)

        guard width > 0, height > 0 else {
            return nil
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high

        context.draw(
            image,
            in: CGRect(
                origin: .zero,
                size: size
            )
        )

        return context.makeImage()
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

enum ThumbnailCGImageLoadResult {
    case loaded(CGImage)
    case noThumbnail
    case error
}
