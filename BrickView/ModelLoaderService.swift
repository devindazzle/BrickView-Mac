//
//  ModelLoaderService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Loads BrickView model data from selected folders and individual
//  BrickLink Studio .io files.
//
//  The service coordinates model file discovery, metadata extraction,
//  and file attribute loading. Invalid model files are retained with
//  an invalid status so that one bad file does not prevent other models
//  from being loaded.
//
//  The service is UI-independent. It does not manage application state,
//  update SwiftUI, or monitor the file system.
//

import Foundation

struct ModelLoaderService {
    private let modelFileService = ModelFileService()
    private let modelMetadataService = ModelMetadataService()

    func loadModels(from folder: URL) async throws -> [Model] {
        let modelURLs = try modelFileService.findModelFiles(
            in: folder
        )

        var models: [Model] = []

        for modelURL in modelURLs {
            let model = loadModelSafely(from: modelURL)
            models.append(model)
        }

        return models
    }

    /// Loads a single model from the supplied .io file.
    ///
    /// This operation is used when a specific model changes while the
    /// folder is being monitored. Keeping single-model loading here
    /// allows the application coordinator to update only the affected
    /// model instead of reloading the entire folder.
    func loadModel(from modelURL: URL) throws -> Model {
        let partCount = try modelMetadataService.partCount(
            for: modelURL
        )

        let fileAttributes = try modelFileService.attributes(
            for: modelURL
        )

        return Model(
            url: modelURL,
            partCount: partCount,
            creationDate: fileAttributes.creationDate,
            modificationDate: fileAttributes.modificationDate,
            status: .valid
        )
    }

    /// Loads a model while preserving the existing fail-safe behaviour
    /// used by folder loading.
    ///
    /// A malformed or otherwise unreadable .io file becomes an invalid
    /// Model instead of preventing other models from being loaded.
    private func loadModelSafely(from modelURL: URL) -> Model {
        do {
            return try loadModel(
                from: modelURL
            )
        } catch {
            return Model(
                url: modelURL,
                status: .invalid
            )
        }
    }
}
