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
//  an .info file with model metadata. This service reads the
//  total part count directly from the .info entry.
//
//  Legacy BrickLink Studio .io files may be password-protected.
//  SwiftZip is used for both protected and unprotected archives
//  and reads only the requested ZIP entry.
//
//  It does not manage application state, update the user interface,
//  discover model files, or generate thumbnails.
//

import Foundation
import SwiftZip

struct ModelMetadataService {
    private let legacyArchivePassword: String = "soho0909"

    func partCount(for modelURL: URL) throws -> Int {
        let archive: ZipArchive

        do {
            archive = try ZipArchive(
                url: modelURL
            )
        } catch {
            throw ModelMetadataError.invalidArchive
        }

        let infoData: Data

        do {
            infoData = try readInfo(
                from: archive,
                password: nil
            )
        } catch {
            do {
                infoData = try readInfo(
                    from: archive,
                    password: legacyArchivePassword
                )
            } catch {
                throw ModelMetadataError.infoFileNotFound
            }
        }

        let metadata = try JSONDecoder().decode(
            ModelInfo.self,
            from: infoData
        )

        return metadata.totalParts
    }

    private func readInfo(
        from archive: ZipArchive,
        password: String?
    ) throws -> Data {
        let reader = try archive.open(
            filename: ".info",
            password: password
        )

        defer {
            reader.close()
        }

        var infoData = Data()

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

            infoData.append(
                buffer,
                count: bytesRead
            )
        }

        return infoData
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
