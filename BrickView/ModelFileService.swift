//
//  ModelFileService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Provides file system operations related to BrickView model files.
//
//  The service is responsible for discovering BrickLink Studio .io
//  files and retrieving file system metadata. It does not manage
//  application state, update the user interface, or parse the
//  contents of model files.
//

import Foundation

struct ModelFileAttributes {
    let creationDate: Date?
    let modificationDate: Date?
}

struct ModelFileService {
    func findModelFiles(in folder: URL) throws -> [URL] {
        let fileManager = FileManager.default

        let urls = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return urls.filter { url in
            url.pathExtension.lowercased() == "io"
        }
    }

    func attributes(for file: URL) throws -> ModelFileAttributes {
        let resourceValues = try file.resourceValues(
            forKeys: [
                .creationDateKey,
                .contentModificationDateKey
            ]
        )

        return ModelFileAttributes(
            creationDate: resourceValues.creationDate,
            modificationDate: resourceValues.contentModificationDate
        )
    }
}
