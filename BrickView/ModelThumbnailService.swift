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
//  Missing thumbnails are treated as a normal condition rather
//  than an error. The service therefore returns nil when the
//  thumbnail is not present.
//
//  The service does not create SwiftUI views, manage application
//  state, or update the user interface.
//

import Foundation
import ZIPFoundation

struct ModelThumbnailService {
    func thumbnailData(for modelURL: URL) throws -> Data? {
        guard let archive = Archive(
            url: modelURL,
            accessMode: .read
        ) else {
            throw ModelThumbnailError.invalidArchive
        }

        guard let thumbnailEntry = archive["thumbnail.png"] else {
            return nil
        }

        var thumbnailData = Data()

        _ = try archive.extract(thumbnailEntry) { data in
            thumbnailData.append(data)
        }

        return thumbnailData
    }
}

private enum ModelThumbnailError: Error {
    case invalidArchive
}
