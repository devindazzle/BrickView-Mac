//
//  ModelMetadataService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Reads metadata from a single BrickLink Studio .io model file.
//
//  A .io file is a ZIP archive containing, among other files,
//  an .info file with model metadata. This service extracts the
//  total part count from that metadata.
//
//  Legacy BrickLink Studio .io files may be password-protected.
//  ZipArchive is used for both protected and unprotected archives.
//
//  It does not manage application state, update the user interface,
//  discover model files, or generate thumbnails.
//

import Foundation
import ZipArchive

struct ModelMetadataService {
    private let legacyArchivePassword: String = "soho0909"

    func partCount(for modelURL: URL) throws -> Int {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "BrickView-Metadata-\(UUID().uuidString)",
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
            throw ModelMetadataError.invalidArchive
        }

        let infoURL = temporaryDirectory
            .appendingPathComponent(".info")

        guard FileManager.default.fileExists(
            atPath: infoURL.path
        ) else {
            throw ModelMetadataError.infoFileNotFound
        }

        let infoData = try Data(contentsOf: infoURL)

        let metadata = try JSONDecoder().decode(
            ModelInfo.self,
            from: infoData
        )

        return metadata.totalParts
    }
}

private struct ModelInfo: Decodable {
    let totalParts: Int

    enum CodingKeys: String, CodingKey {
        case totalParts = "total_parts"
    }
}

private enum ModelMetadataError: Error {
    case invalidArchive
    case infoFileNotFound
}
