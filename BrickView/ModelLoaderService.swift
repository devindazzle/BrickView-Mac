//
//  ModelLoaderService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Loads BrickView model data from a selected folder.
//
//  The service coordinates model file discovery and metadata
//  extraction. It does not manage application state or update
//  the user interface.
//

import Foundation

struct ModelLoaderService {
    private let modelFileService = ModelFileService()
    private let modelMetadataService = ModelMetadataService()

    func loadModels(from folder: URL) async throws -> [Model] {
        let modelURLs = try modelFileService.findModelFiles(in: folder)

        var models: [Model] = []

        for modelURL in modelURLs {
            let partCount = try modelMetadataService.partCount(
                for: modelURL
            )

            let model = Model(
                url: modelURL,
                partCount: partCount
            )

            models.append(model)
        }

        return models
    }
}
