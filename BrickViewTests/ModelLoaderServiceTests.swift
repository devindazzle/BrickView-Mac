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
}
