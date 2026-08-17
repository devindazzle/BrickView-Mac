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
//  SwiftZip is used for both protected and unprotected archives
//  and reads only the requested ZIP entry.
//
//  Missing thumbnails are treated as a normal condition rather
//  than an error. The service therefore returns nil when the
//  thumbnail is not present.
//
//  The service does not create SwiftUI views, manage application
//  state, or update the user interface.
//

import Foundation
import SwiftZip

struct ModelThumbnailService {
    private let legacyArchivePassword: String = "soho0909"

    func thumbnailData(for modelURL: URL) throws -> Data? {
        let archive: ZipArchive

        do {
            archive = try ZipArchive(
                url: modelURL
            )
        } catch {
            throw ModelThumbnailError.invalidArchive
        }

        do {
            return try readThumbnail(
                from: archive,
                password: nil
            )
        } catch {
            do {
                return try readThumbnail(
                    from: archive,
                    password: legacyArchivePassword
                )
            } catch {
                return nil
            }
        }
    }

    private func readThumbnail(
        from archive: ZipArchive,
        password: String?
    ) throws -> Data {
        let reader = try archive.open(
            filename: "thumbnail.png",
            password: password
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

        return thumbnailData
    }
}

private enum ModelThumbnailError: Error {
    case invalidArchive
}
