//
//  ZipArchivePasswordTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Verifies that SwiftZip can read legacy password-protected
//  BrickLink Studio .io files using the known Studio password.
//

import XCTest
import SwiftZip

final class ZipArchivePasswordTests: XCTestCase {
    func testLegacyStudioIOFileCanBeOpenedWithPassword() throws {
        let fileName = "MOC-41818_dandelbaum_Large tower connection 6085-6059"
        let fileExtension = "io"

        guard let fileURL = Bundle(for: Self.self).url(
            forResource: fileName,
            withExtension: fileExtension
        ) else {
            XCTFail("Test .io file was not found in the test bundle.")
            return
        }

        let archive = try ZipArchive(
            url: fileURL
        )

        let reader = try archive.open(
            filename: "thumbnail.png",
            password: "soho0909"
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
            thumbnailData.isEmpty,
            "The password-protected .io file should contain thumbnail data."
        )
    }
}
