//
//  ModelThumbnailServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
@testable import BrickView

final class ModelThumbnailServiceTests: XCTestCase {

    func testThumbnailDataIsLoadedFromIOFile() throws {
        let bundle = Bundle(for: ModelThumbnailServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let service = ModelThumbnailService()

        let thumbnailData = try service.thumbnailData(
            for: fileURL
        )

        XCTAssertNotNil(thumbnailData)
        XCTAssertFalse(thumbnailData?.isEmpty ?? true)
    }

    func testMissingThumbnailReturnsNil() throws {
        let bundle = Bundle(for: ModelThumbnailServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-no-thumbnail",
                withExtension: "io"
            )
        )

        let service = ModelThumbnailService()

        let thumbnailData = try service.thumbnailData(
            for: fileURL
        )

        XCTAssertNil(thumbnailData)
    }
}
