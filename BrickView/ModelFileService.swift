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
//  files in a selected folder. It does not manage application state,
//  update the user interface, or parse the contents of model files.
//

import Foundation

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
}
