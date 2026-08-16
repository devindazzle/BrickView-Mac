//
//  ThumbnailLoaderTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 16/08/2026.
//

import XCTest
import CoreGraphics
@testable import BrickView

final class ThumbnailLoaderTests: XCTestCase {

    func testThumbnailIsLoadedAtRequestedSize() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let loader = ThumbnailLoader()

        let result = try await loader.load(
            for: fileURL,
            size: CGSize(
                width: 360,
                height: 220
            )
        )

        guard case .loaded(let image) = result else {
            XCTFail("Expected a loaded thumbnail")
            return
        }

        XCTAssertEqual(
            image.width,
            360
        )

        XCTAssertEqual(
            image.height,
            220
        )
    }

    func testDifferentThumbnailSizesProduceDifferentImageSizes() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let loader = ThumbnailLoader()

        let firstSize = CGSize(
            width: 360,
            height: 220
        )

        let secondSize = CGSize(
            width: 720,
            height: 440
        )

        let firstResult = try await loader.load(
            for: fileURL,
            size: firstSize
        )

        let secondResult = try await loader.load(
            for: fileURL,
            size: secondSize
        )

        guard case .loaded(let firstImage) = firstResult else {
            XCTFail("Expected the first thumbnail to be loaded")
            return
        }

        guard case .loaded(let secondImage) = secondResult else {
            XCTFail("Expected the second thumbnail to be loaded")
            return
        }

        XCTAssertEqual(
            CGFloat(firstImage.width),
            firstSize.width
        )

        XCTAssertEqual(
            CGFloat(firstImage.height),
            firstSize.height
        )

        XCTAssertEqual(
            CGFloat(secondImage.width),
            secondSize.width
        )

        XCTAssertEqual(
            CGFloat(secondImage.height),
            secondSize.height
        )
    }

    func testCacheIsInvalidatedWhenFileModificationDateChanges() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let sourceURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectoryURL,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectoryURL
            )
        }

        let testFileURL = temporaryDirectoryURL
            .appendingPathComponent("test-model.io")

        try FileManager.default.copyItem(
            at: sourceURL,
            to: testFileURL
        )

        let loader = ThumbnailLoader()

        let size = CGSize(
            width: 360,
            height: 220
        )

        let firstResult = try await loader.load(
            for: testFileURL,
            size: size
        )

        guard case .loaded(let firstImage) = firstResult else {
            XCTFail("Expected the first thumbnail to be loaded")
            return
        }

        let cachedResult = try await loader.load(
            for: testFileURL,
            size: size
        )

        guard case .loaded(let cachedImage) = cachedResult else {
            XCTFail("Expected the cached thumbnail to be loaded")
            return
        }

        XCTAssertTrue(
            firstImage === cachedImage,
            "Expected the second load to use the cached CGImage"
        )

        let originalModificationDate = try XCTUnwrap(
            FileManager.default.attributesOfItem(
                atPath: testFileURL.path
            )[.modificationDate] as? Date
        )

        let newModificationDate = originalModificationDate
            .addingTimeInterval(60)

        try FileManager.default.setAttributes(
            [
                .modificationDate: newModificationDate
            ],
            ofItemAtPath: testFileURL.path
        )

        let updatedModificationDate = try XCTUnwrap(
            FileManager.default.attributesOfItem(
                atPath: testFileURL.path
            )[.modificationDate] as? Date
        )

        XCTAssertNotEqual(
            originalModificationDate,
            updatedModificationDate,
            "Expected the file modification date to change"
        )

        let reloadedResult = try await loader.load(
            for: testFileURL,
            size: size
        )

        guard case .loaded(let reloadedImage) = reloadedResult else {
            XCTFail("Expected the thumbnail to be reloaded")
            return
        }

        XCTAssertFalse(
            firstImage === reloadedImage,
            "Expected a new CGImage after the file modification date changed"
        )
    }

    func testCacheIsInvalidatedWhenThumbnailSizeChanges() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let loader = ThumbnailLoader()

        let firstSize = CGSize(
            width: 360,
            height: 220
        )

        let secondSize = CGSize(
            width: 720,
            height: 440
        )

        let firstResult = try await loader.load(
            for: fileURL,
            size: firstSize
        )

        guard case .loaded(let firstImage) = firstResult else {
            XCTFail("Expected the first thumbnail to be loaded")
            return
        }

        let cachedResult = try await loader.load(
            for: fileURL,
            size: firstSize
        )

        guard case .loaded(let cachedImage) = cachedResult else {
            XCTFail("Expected the cached thumbnail to be loaded")
            return
        }

        XCTAssertTrue(
            firstImage === cachedImage,
            "Expected the second load to use the cached CGImage"
        )

        let resizedResult = try await loader.load(
            for: fileURL,
            size: secondSize
        )

        guard case .loaded(let resizedImage) = resizedResult else {
            XCTFail("Expected a resized thumbnail to be loaded")
            return
        }

        XCTAssertFalse(
            firstImage === resizedImage,
            "Expected a new CGImage when the thumbnail size changed"
        )

        XCTAssertEqual(
            CGFloat(resizedImage.width),
            secondSize.width
        )

        XCTAssertEqual(
            CGFloat(resizedImage.height),
            secondSize.height
        )
    }

    func testCancelledLoadDoesNotReturnThumbnail() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let loader = ThumbnailLoader()

        let loadTask = Task {
            try await loader.load(
                for: fileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                )
            )
        }

        loadTask.cancel()

        do {
            _ = try await loadTask.value
            XCTFail("Expected the cancelled load to throw")
        } catch is CancellationError {
            // Expected result.
        } catch {
            XCTFail(
                "Expected CancellationError, got \(error)"
            )
        }
    }

    func testCancelledWaitingLoadDoesNotStartAfterCancellation() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let firstFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let secondFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-no-thumbnail",
                withExtension: "io"
            )
        )

        let loadStarted = XCTestExpectation(
            description: "First load started"
        )

        let releaseFirstLoad = XCTestExpectation(
            description: "First load may be released"
        )

        let secondLoadStarted = XCTestExpectation(
            description: "Second load started"
        )

        secondLoadStarted.isInverted = true

        let thumbnailDataLoader: @Sendable (URL) throws -> Data? = { url in
            if url == firstFileURL {
                loadStarted.fulfill()

                _ = XCTWaiter.wait(
                    for: [
                        releaseFirstLoad
                    ],
                    timeout: 5.0
                )
            } else if url == secondFileURL {
                secondLoadStarted.fulfill()
            }

            let service = ModelThumbnailService()

            return try service.thumbnailData(
                for: url
            )
        }

        let loader = ThumbnailLoader(
            maximumConcurrentLoads: 1,
            thumbnailDataLoader: thumbnailDataLoader
        )

        let firstLoadTask = Task {
            try await loader.load(
                for: firstFileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                )
            )
        }

        wait(
            for: [
                loadStarted
            ],
            timeout: 2.0
        )

        let secondLoadTask = Task {
            try await loader.load(
                for: secondFileURL,
                size: CGSize(
                    width: 720,
                    height: 440
                )
            )
        }

        secondLoadTask.cancel()

        releaseFirstLoad.fulfill()

        _ = try? await firstLoadTask.value

        do {
            _ = try await secondLoadTask.value
            XCTFail(
                "Expected the cancelled waiting load to throw"
            )
        } catch is CancellationError {
            // Expected result.
        } catch {
            XCTFail(
                "Expected CancellationError, got \(error)"
            )
        }

        wait(
            for: [
                secondLoadStarted
            ],
            timeout: 0.5
        )
    }

    func testCancelledWaitingLoadIsRemovedFromQueue() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let firstFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let secondFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-no-thumbnail",
                withExtension: "io"
            )
        )

        let firstLoadStarted = XCTestExpectation(
            description: "First load started"
        )

        let releaseFirstLoad = DispatchSemaphore(
            value: 0
        )

        let thumbnailDataLoader: @Sendable (URL) throws -> Data? = { url in
            if url == firstFileURL {
                firstLoadStarted.fulfill()

                releaseFirstLoad.wait()
            }

            let service = ModelThumbnailService()

            return try service.thumbnailData(
                for: url
            )
        }

        let loader = ThumbnailLoader(
            maximumConcurrentLoads: 1,
            thumbnailDataLoader: thumbnailDataLoader
        )

        let firstLoadTask = Task {
            try await loader.load(
                for: firstFileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                )
            )
        }

        wait(
            for: [
                firstLoadStarted
            ],
            timeout: 2.0
        )

        let secondLoadTask = Task {
            try await loader.load(
                for: secondFileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                )
            )
        }

        while await loader.waitingLoadCount() == 0 {
            await Task.yield()
        }

        let waitingLoadCount = await loader.waitingLoadCount()

        XCTAssertEqual(
            waitingLoadCount,
            1
        )

        secondLoadTask.cancel()

        var waitingLoadCountAfterCancellation =
            await loader.waitingLoadCount()

        var remainingAttempts = 1000

        while waitingLoadCountAfterCancellation != 0 &&
                remainingAttempts > 0 {
            await Task.yield()

            waitingLoadCountAfterCancellation =
                await loader.waitingLoadCount()

            remainingAttempts -= 1
        }

        XCTAssertEqual(
            waitingLoadCountAfterCancellation,
            0,
            "Expected cancelled request to be removed from the queue"
        )

        releaseFirstLoad.signal()

        _ = try? await firstLoadTask.value
        _ = try? await secondLoadTask.value
    }

    func testHighPriorityLoadStartsBeforeNormalPriorityLoad() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let firstFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let normalFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-no-thumbnail",
                withExtension: "io"
            )
        )

        let highFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-invalid",
                withExtension: "io"
            )
        )

        let firstLoadStarted = XCTestExpectation(
            description: "First load started"
        )

        let highLoadStarted = XCTestExpectation(
            description: "High priority load started"
        )

        let normalLoadStarted = XCTestExpectation(
            description: "Normal priority load started"
        )

        normalLoadStarted.isInverted = true

        let releaseFirstLoad = DispatchSemaphore(
            value: 0
        )

        let releaseHighLoad = DispatchSemaphore(
            value: 0
        )

        let thumbnailDataLoader: @Sendable (URL) throws -> Data? = { url in
            if url == firstFileURL {
                firstLoadStarted.fulfill()
                releaseFirstLoad.wait()
            } else if url == normalFileURL {
                normalLoadStarted.fulfill()
            } else if url == highFileURL {
                highLoadStarted.fulfill()
                releaseHighLoad.wait()
            }

            let service = ModelThumbnailService()

            return try service.thumbnailData(
                for: url
            )
        }

        let loader = ThumbnailLoader(
            maximumConcurrentLoads: 1,
            thumbnailDataLoader: thumbnailDataLoader
        )

        let firstLoadTask = Task {
            try await loader.load(
                for: firstFileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                ),
                priority: .normal
            )
        }

        wait(
            for: [
                firstLoadStarted
            ],
            timeout: 2.0
        )

        let normalLoadTask = Task {
            try await loader.load(
                for: normalFileURL,
                size: CGSize(
                    width: 360,
                    height: 220
                ),
                priority: .normal
            )
        }

        let highLoadTask = Task {
            try await loader.load(
                for: highFileURL,
                size: CGSize(
                    width: 720,
                    height: 440
                ),
                priority: .high
            )
        }

        while await loader.waitingLoadCount() < 2 {
            await Task.yield()
        }

        releaseFirstLoad.signal()

        wait(
            for: [
                highLoadStarted
            ],
            timeout: 2.0
        )

        wait(
            for: [
                normalLoadStarted
            ],
            timeout: 0.5
        )

        releaseHighLoad.signal()

        _ = try? await firstLoadTask.value
        _ = try? await normalLoadTask.value
        _ = try? await highLoadTask.value
    }

    func testUncachedThumbnailLoadPerformance() async throws {
        let bundle = Bundle(for: ThumbnailLoaderTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let size = CGSize(
            width: 360,
            height: 220
        )

        let iterationCount = 5
        var durations: [TimeInterval] = []

        for _ in 0..<iterationCount {
            let loader = ThumbnailLoader()

            let startTime = Date()

            let result = try await loader.load(
                for: fileURL,
                size: size
            )

            let duration = Date().timeIntervalSince(
                startTime
            )

            durations.append(duration)

            guard case .loaded(let image) = result else {
                XCTFail("Expected a loaded thumbnail")
                return
            }

            XCTAssertEqual(
                CGFloat(image.width),
                size.width
            )

            XCTAssertEqual(
                CGFloat(image.height),
                size.height
            )
        }

        let minimumDuration = durations.min() ?? 0
        let maximumDuration = durations.max() ?? 0
        let averageDuration =
            durations.reduce(0, +) / Double(iterationCount)

        print(
            """
            Thumbnail performance diagnostic:
              iterations: \(iterationCount)
              minimum: \(minimumDuration) seconds
              maximum: \(maximumDuration) seconds
              average: \(averageDuration) seconds
            """
        )
    }
}
