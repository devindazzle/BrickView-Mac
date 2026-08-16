//
//  ThumbnailLoaderTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 16/08/2026.
//

import XCTest
import AppKit
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

        XCTAssertEqual(image.size.width, 360)
        XCTAssertEqual(image.size.height, 220)
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

        let firstResult = try await loader.load(
            for: fileURL,
            size: CGSize(
                width: 360,
                height: 220
            )
        )

        let secondResult = try await loader.load(
            for: fileURL,
            size: CGSize(
                width: 720,
                height: 440
            )
        )

        guard case .loaded(let firstImage) = firstResult else {
            XCTFail("Expected the first thumbnail to be loaded")
            return
        }

        guard case .loaded(let secondImage) = secondResult else {
            XCTFail("Expected the second thumbnail to be loaded")
            return
        }

        XCTAssertEqual(firstImage.size.width, 360)
        XCTAssertEqual(firstImage.size.height, 220)

        XCTAssertEqual(secondImage.size.width, 720)
        XCTAssertEqual(secondImage.size.height, 440)
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
            "Expected the second load to use the cached image"
        )

        let originalModificationDate = try XCTUnwrap(
            FileManager.default.attributesOfItem(
                atPath: testFileURL.path
            )[.modificationDate] as? Date
        )

        let newModificationDate = originalModificationDate.addingTimeInterval(60)

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
            "Expected a new image after the file modification date changed"
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
            "Expected the second load to use the cached image"
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
            "Expected a new image when the thumbnail size changed"
        )

        XCTAssertEqual(
            resizedImage.size.width,
            secondSize.width
        )

        XCTAssertEqual(
            resizedImage.size.height,
            secondSize.height
        )
    }
}
