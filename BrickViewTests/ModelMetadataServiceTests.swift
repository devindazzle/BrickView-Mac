//
//  ModelMetadataServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
import ZipArchive

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

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "BrickView-Metadata-Test-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        var extractionError: NSError?

        let extractedFiles = SSZipArchive.unzipFile(
            atPath: fileURL.path,
            toDestination: temporaryDirectory.path,
            preserveAttributes: false,
            overwrite: true,
            password: nil,
            error: &extractionError,
            delegate: nil
        )

        XCTAssertTrue(
            extractedFiles,
            "Failed to extract .io file: \(extractionError?.localizedDescription ?? "Unknown error")"
        )

        let thumbnailURL = temporaryDirectory
            .appendingPathComponent("thumbnail.png")

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: thumbnailURL.path
            )
        )
    }
}
