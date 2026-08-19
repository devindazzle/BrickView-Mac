//
//  ModelBrowserCoordinator.swift
//  BrickView
//
//  Created by Kim Pedersen on 18/08/2026.
//

//
//  Purpose:
//  Coordinates the folder and model state used by the BrickView browser.
//
//  The coordinator owns the currently selected folder, its
//  security-scoped access session, the current collection of models,
//  and the lifecycle of the folder monitor.
//
//  It also coordinates model loading through ModelLoaderService and
//  applies individual model updates reported by the folder monitor.
//
//  The coordinator is intentionally UI-independent. SwiftUI views
//  observe its published state rather than managing folder access,
//  model loading, or model collection state themselves.
//
//  FSEvents does not guarantee that every file-system provider reports
//  deletion through an ItemRemoved flag. Some providers, including the
//  Dropbox folder used during development, can instead report a changed
//  path which no longer exists. The coordinator therefore treats a
//  changed .io path that no longer exists as a removal.
//

import Foundation
import Combine

@MainActor
final class ModelBrowserCoordinator: ObservableObject {

    @Published private(set) var selectedFolder: URL?
    @Published private(set) var models: [Model] = []
    @Published private(set) var loadingError: String?

    private var folderAccessSession: FolderAccessSession?
    private var folderMonitoringTask: Task<Void, Never>?
    private var modelLoadingTask: Task<Void, Never>?

    private let modelLoaderService = ModelLoaderService()
    private let modelFolderMonitorService = ModelFolderMonitorService()

    func selectFolder(_ folder: URL) -> Bool {
        stopFolderMonitoring()
        cancelModelLoading()

        guard let accessSession = FolderAccessSession(folder: folder) else {
            selectedFolder = nil
            folderAccessSession = nil
            clearModels()
            return false
        }

        folderAccessSession = accessSession
        selectedFolder = accessSession.folder

        loadModels(
            from: accessSession.folder
        )

        startFolderMonitoring(
            for: accessSession.folder
        )

        return true
    }

    func loadModels(from folder: URL) {
        cancelModelLoading()

        let modelLoaderService = self.modelLoaderService

        modelLoadingTask = Task { [weak self] in
            do {
                let loadedModels = try await modelLoaderService.loadModels(
                    from: folder
                )

                guard !Task.isCancelled else {
                    return
                }

                guard let coordinator = self else {
                    return
                }

                coordinator.models = loadedModels
                coordinator.loadingError = nil

            } catch {
                guard !Task.isCancelled else {
                    return
                }

                guard let coordinator = self else {
                    return
                }

                coordinator.models = []
                coordinator.loadingError = error.localizedDescription
            }
        }
    }

    /// Inserts a model if it is new, or replaces the existing model
    /// with the same normalized filesystem path when the model was
    /// reloaded after a file change.
    func upsertModel(_ model: Model) {
        let modelPath: String = normalizedModelPath(
            model.id
        )

        if let index = models.firstIndex(
            where: {
                normalizedModelPath($0.id) == modelPath
            }
        ) {
            models[index] = model
        } else {
            models.append(model)
        }
    }

    /// Removes the model identified by the supplied URL.
    ///
    /// FSEvents and FileManager can expose the same filesystem location
    /// through different URL representations on macOS. Comparing
    /// normalized paths keeps model identity stable.
    func removeModel(with modelURL: URL) {
        let modelPath: String = normalizedModelPath(
            modelURL
        )

        models.removeAll {
            normalizedModelPath($0.id) == modelPath
        }
    }

    func clearModels() {
        models = []
        loadingError = nil
    }

    /// Starts consuming file-system events for the selected folder.
    ///
    /// The monitor reports filesystem changes independently of model
    /// semantics. The coordinator translates those events into updates
    /// to its model collection.
    private func startFolderMonitoring(for folder: URL) {
        let stream = modelFolderMonitorService.startMonitoring(
            folder: folder
        )

        folderMonitoringTask = Task {
            for await change in stream {
                await handleFolderChange(
                    change
                )
            }
        }
    }

    /// Handles a single folder-monitor event.
    ///
    /// Changed events are reloaded when they currently represent an
    /// existing .io file. If the path no longer exists, the event is
    /// treated as a removal. Explicit removed events are also handled.
    private func handleFolderChange(
        _ change: ModelFolderChange
    ) async {
        switch change {
        case let .changed(url):
            await handleChangedFile(
                at: url
            )

        case let .removed(url):
            handleRemovedFile(
                at: url
            )
        }
    }

    /// Reloads one changed .io file and updates only that model.
    ///
    /// If the path no longer exists, the change is treated as a removal.
    /// This is required because some filesystem providers do not report
    /// deletions through FSEvents' ItemRemoved flag.
    private func handleChangedFile(
        at url: URL
    ) async {
        guard url.pathExtension.lowercased() == "io" else {
            return
        }

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            removeModel(
                with: url
            )

            return
        }

        do {
            let model = try modelLoaderService.loadModel(
                from: url
            )

            guard !Task.isCancelled else {
                return
            }

            upsertModel(
                model
            )
        } catch {
            guard !Task.isCancelled else {
                return
            }

            let invalidModel = Model(
                url: url,
                status: .invalid
            )

            upsertModel(
                invalidModel
            )
        }
    }

    /// Removes a model when the file system reports that its .io file
    /// has been removed explicitly.
    private func handleRemovedFile(
        at url: URL
    ) {
        guard url.pathExtension.lowercased() == "io" else {
            return
        }

        removeModel(
            with: url
        )
    }

    /// Produces a stable filesystem path for model identity.
    ///
    /// macOS may expose /var as /private/var depending on which API
    /// produced the URL. For model identity these paths represent the
    /// same filesystem location, so the /private prefix is removed.
    private func normalizedModelPath(
        _ url: URL
    ) -> String {
        let path: String = url.standardizedFileURL.path

        if path.hasPrefix("/private/var/") {
            return String(
                path.dropFirst("/private".count)
            )
        }

        return path
    }

    /// Cancels the active model-loading task.
    ///
    /// A new folder selection must never allow a previous asynchronous
    /// load to update the coordinator after the user has selected another
    /// folder.
    private func cancelModelLoading() {
        modelLoadingTask?.cancel()
        modelLoadingTask = nil
    }

    /// Stops the active folder monitor.
    ///
    /// Cancellation alone does not guarantee that the AsyncStream will
    /// finish, so the service is explicitly stopped as well. This keeps
    /// folder switching and coordinator shutdown deterministic.
    private func stopFolderMonitoring() {
        folderMonitoringTask?.cancel()
        folderMonitoringTask = nil

        modelFolderMonitorService.stopMonitoring()
    }

    deinit {
        folderMonitoringTask?.cancel()
        modelLoadingTask?.cancel()
        modelFolderMonitorService.stopMonitoring()
    }
}
