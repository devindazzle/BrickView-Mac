//
//  ModelLoaderServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
@testable import BrickView

final class ModelLoaderServiceTests: XCTestCase {

    func testLoadModelsFromFolder() async throws {
        let bundle = Bundle(for: ModelLoaderServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let folderURL = fileURL.deletingLastPathComponent()

        let service = ModelLoaderService()

        let models = try await service.loadModels(from: folderURL)

        let model = try XCTUnwrap(
            models.first { $0.filename == "383-knights-tournament.io" }
        )

        XCTAssertEqual(model.partCount, 232)
    }
    
    
    func testLoadModelsHandlesValidInvalidAndMissingThumbnailFiles() async throws {
        let bundle = Bundle(for: ModelLoaderServiceTests.self)

        let validFileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let folderURL = validFileURL.deletingLastPathComponent()

        let service = ModelLoaderService()

        let models = try await service.loadModels(from: folderURL)

        let validModel = try XCTUnwrap(
            models.first {
                $0.filename == "383-knights-tournament.io"
            }
        )

        let noThumbnailModel = try XCTUnwrap(
            models.first {
                $0.filename == "383-knights-tournament-no-thumbnail.io"
            }
        )

        let invalidModel = try XCTUnwrap(
            models.first {
                $0.filename == "383-knights-tournament-invalid.io"
            }
        )

        XCTAssertEqual(validModel.status, .valid)
        XCTAssertEqual(validModel.partCount, 232)

        XCTAssertEqual(noThumbnailModel.status, .valid)
        XCTAssertEqual(noThumbnailModel.partCount, 232)

        XCTAssertEqual(invalidModel.status, .invalid)
        XCTAssertNil(invalidModel.partCount)
    }
    
}
