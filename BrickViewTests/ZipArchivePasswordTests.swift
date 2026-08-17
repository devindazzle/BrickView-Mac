//
//  ZipArchivePasswordTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Verifies that ZipArchive can read legacy password-protected
//  BrickLink Studio .io files using the known Studio password.
//

import XCTest
import ZipArchive

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

        XCTAssertTrue(
            SSZipArchive.isFilePasswordProtected(
                atPath: fileURL.path
            )
        )

        var passwordError: NSError?

        let passwordIsValid = SSZipArchive.isPasswordValidForArchive(
            atPath: fileURL.path,
            password: "soho0909",
            error: &passwordError
        )

        XCTAssertTrue(
            passwordIsValid,
            "Password validation failed: \(passwordError?.localizedDescription ?? "Unknown error")"
        )

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "BrickView-ZipArchive-Password-Test-\(UUID().uuidString)",
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
            password: "soho0909",
            error: &extractionError,
            delegate: nil
        )

        XCTAssertNotNil(
            extractedFiles,
            "Extraction failed: \(extractionError?.localizedDescription ?? "Unknown error")"
        )

        let thumbnailURL = temporaryDirectory
            .appendingPathComponent("thumbnail.png")

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: thumbnailURL.path
            ),
            "thumbnail.png was not extracted from the password-protected .io file."
        )

        let thumbnailData = try Data(contentsOf: thumbnailURL)

        XCTAssertFalse(
            thumbnailData.isEmpty,
            "thumbnail.png was extracted but contains no data."
        )
    }
}
