//
//  ModelThumbnailService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Extracts thumbnail data from a BrickLink Studio .io model file.
//
//  A .io file is a ZIP archive containing a thumbnail.png file
//  when a model has a generated thumbnail.
//
//  Legacy BrickLink Studio .io files may be password-protected.
//  ZipArchive is used for both protected and unprotected archives.
//
//  Missing thumbnails are treated as a normal condition rather
//  than an error. The service therefore returns nil when the
//  thumbnail is not present.
//
//  The service does not create SwiftUI views, manage application
//  state, or update the user interface.
//

import Foundation
import ZipArchive

struct ModelThumbnailService {
    private let legacyArchivePassword: String = "soho0909"

    func thumbnailData(for modelURL: URL) throws -> Data? {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "BrickView-Thumbnail-\(UUID().uuidString)",
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

        let isPasswordProtected = SSZipArchive.isFilePasswordProtected(
            atPath: modelURL.path
        )

        let password: String? = isPasswordProtected
            ? legacyArchivePassword
            : nil

        var extractionError: NSError?

        let extractedFiles = SSZipArchive.unzipFile(
            atPath: modelURL.path,
            toDestination: temporaryDirectory.path,
            preserveAttributes: false,
            overwrite: true,
            password: password,
            error: &extractionError,
            delegate: nil
        )

        guard extractedFiles else {
            throw ModelThumbnailError.invalidArchive
        }

        let thumbnailURL = temporaryDirectory
            .appendingPathComponent("thumbnail.png")

        guard FileManager.default.fileExists(
            atPath: thumbnailURL.path
        ) else {
            return nil
        }

        return try Data(contentsOf: thumbnailURL)
    }
}

private enum ModelThumbnailError: Error {
    case invalidArchive
}
