//
//  ModelMetadataServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
import ZIPFoundation

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
    
    
    func testIOFileContainsThumbnail() throws {
        let bundle = Bundle(for: ModelMetadataServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let archive = try XCTUnwrap(
            Archive(
                url: fileURL,
                accessMode: .read
            )
        )

        XCTAssertNotNil(archive["thumbnail.png"])
    }
    
}
