//
//  SwiftZipIOTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Verifies that SwiftZip 0.0.5 can read the ZIP structures
//  used by BrickLink Studio .io files.
//
//  This is temporary validation code used before deciding whether
//  SwiftZip should replace the current ZIP implementation.
//

import XCTest
import SwiftZip

final class SwiftZipIOTests: XCTestCase {
    private let legacyPassword: String = "soho0909"

    func testNormalIOCanReadInfoEntry() throws {
        let fileURL = try testFileURL(
            named: "383-knights-tournament"
        )

        let data = try readEntry(
            from: fileURL,
            filename: ".info"
        )

        XCTAssertFalse(
            data.isEmpty,
            "The .info entry should contain data."
        )
    }

    func testNormalIOCanReadThumbnailEntry() throws {
        let fileURL = try testFileURL(
            named: "383-knights-tournament"
        )

        let data = try readEntry(
            from: fileURL,
            filename: "thumbnail.png"
        )

        XCTAssertFalse(
            data.isEmpty,
            "The thumbnail.png entry should contain data."
        )
    }

    func testLegacyPasswordProtectedIOCanReadThumbnailEntry() throws {
        let fileURL = try testFileURL(
            named: "MOC-41818_dandelbaum_Large tower connection 6085-6059"
        )

        let data = try readEntry(
            from: fileURL,
            filename: "thumbnail.png",
            password: legacyPassword
        )

        XCTAssertFalse(
            data.isEmpty,
            "The password-protected thumbnail.png entry should contain data."
        )
    }

    func testIOWithoutThumbnailReportsMissingEntry() throws {
        let fileURL = try testFileURL(
            named: "383-knights-tournament-no-thumbnail"
        )

        let archive = try ZipArchive(
            url: fileURL
        )

        XCTAssertThrowsError(
            try archive.open(
                filename: "thumbnail.png"
            )
        )
    }

    func testInvalidIOFailsToOpenArchive() throws {
        let fileURL = try testFileURL(
            named: "383-knights-tournament-invalid"
        )

        XCTAssertThrowsError(
            try ZipArchive(
                url: fileURL
            )
        )
    }

    private func testFileURL(
        named name: String
    ) throws -> URL {
        let bundle = Bundle(for: Self.self)

        return try XCTUnwrap(
            bundle.url(
                forResource: name,
                withExtension: "io"
            )
        )
    }

    private func readEntry(
        from fileURL: URL,
        filename: String,
        password: String? = nil
    ) throws -> Data {
        let archive = try ZipArchive(
            url: fileURL
        )

        let reader = try archive.open(
            filename: filename,
            password: password
        )

        defer {
            reader.close()
        }

        var data = Data()

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

            data.append(
                buffer,
                count: bytesRead
            )
        }

        return data
    }
}
