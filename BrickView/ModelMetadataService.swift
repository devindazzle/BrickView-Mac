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
//  It does not manage application state, update the user interface,
//  discover model files, or generate thumbnails.
//

import Foundation
import ZIPFoundation

struct ModelMetadataService {
    func partCount(for modelURL: URL) throws -> Int {
        guard let archive = Archive(
            url: modelURL,
            accessMode: .read
        ) else {
            throw ModelMetadataError.invalidArchive
        }

        guard let infoEntry = archive[".info"] else {
            throw ModelMetadataError.infoFileNotFound
        }

        var infoData = Data()

        _ = try archive.extract(infoEntry) { data in
            infoData.append(data)
        }

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
