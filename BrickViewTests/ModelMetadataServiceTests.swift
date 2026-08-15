//
//  ModelMetadataServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
@testable import BrickView

final class ModelMetadataServiceTests: XCTestCase {

    func testPartCountReadsTotalPartsFromIOFile() throws {
        let bundle = Bundle(for: ModelMetadataServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let service = ModelMetadataService()

        let partCount = try service.partCount(for: fileURL)

        XCTAssertEqual(partCount, 232)
    }
}
