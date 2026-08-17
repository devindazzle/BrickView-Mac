//
//  ModelMetadataServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import XCTest
import SwiftZip

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

        let partCount = try service.partCount(
            for: fileURL
        )

        XCTAssertEqual(
            partCount,
            232
        )
    }

    func testIOFileContainsThumbnail() throws {
        let bundle = Bundle(for: ModelMetadataServiceTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let archive = try ZipArchive(
            url: fileURL
        )

        let reader = try archive.open(
            filename: "thumbnail.png"
        )

        defer {
            reader.close()
        }

        var thumbnailData = Data()

        var buffer = [UInt8](
            repeating: 0,
            count: 64 * 1024
        )

        while true {
            let bytesRead = try buffer.withUnsafeMutableBytes { rawBuffer in
                try reader.read(
                    buf: rawBuffer
                )
            }

            if bytesRead <= 0 {
                break
            }

            thumbnailData.append(
                buffer,
                count: bytesRead
            )
        }

        XCTAssertFalse(
            thumbnailData.isEmpty
        )
    }

    func testPasswordProtectedIOFileReadsPartCount() throws {
        let bundle = Bundle(for: Self.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "MOC-41818_dandelbaum_Large tower connection 6085-6059",
                withExtension: "io"
            )
        )

        let service = ModelMetadataService()

        let partCount = try service.partCount(
            for: fileURL
        )

        XCTAssertGreaterThan(
            partCount,
            0,
            "The password-protected .io file should contain a valid part count."
        )
    }
}
