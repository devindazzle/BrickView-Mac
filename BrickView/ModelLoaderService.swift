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
//  extraction. Invalid model files are retained in the result
//  with an invalid status so that one bad file does not prevent
//  other models from being loaded.
//

import Foundation

struct ModelLoaderService {
    private let modelFileService = ModelFileService()
    private let modelMetadataService = ModelMetadataService()

    func loadModels(from folder: URL) async throws -> [Model] {
        let modelURLs = try modelFileService.findModelFiles(in: folder)

        var models: [Model] = []

        for modelURL in modelURLs {
            do {
                let partCount = try modelMetadataService.partCount(
                    for: modelURL
                )

                let fileAttributes = try modelFileService.attributes(
                    for: modelURL
                )

                let model = Model(
                    url: modelURL,
                    partCount: partCount,
                    creationDate: fileAttributes.creationDate,
                    modificationDate: fileAttributes.modificationDate,
                    status: .valid
                )

                models.append(model)
            } catch {
                let model = Model(
                    url: modelURL,
                    status: .invalid
                )

                models.append(model)
            }
        }

        return models
    }
}
