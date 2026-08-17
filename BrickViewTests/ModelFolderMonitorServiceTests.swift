//
//  ModelFolderMonitorServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Verifies that ModelFolderMonitorService detects and classifies
//  file-system changes in a monitored folder.
//
//  The tests use temporary directories so that they are isolated from
//  the user's actual BrickView folders and from the project's bundled
//  test resources.
//
//  FSEvents may report different combinations of low-level flags for
//  the same file-system operation. The tests therefore verify the
//  service's stable application-level semantics:
//
//      changed(URL)
//      removed(URL)
//
//  Model-specific filtering and model loading remain outside the scope
//  of this service.
//

import XCTest
@testable import BrickView

final class ModelFolderMonitorServiceTests: XCTestCase {

    func testMonitorReportsCreatedFileAsChanged() async throws {
        let fileManager = FileManager.default
        let temporaryFolder = fileManager.temporaryDirectory
            .appendingPathComponent(
                "BrickViewModelFolderMonitorTest-\(UUID().uuidString)",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(at: temporaryFolder)
        }

        let service = ModelFolderMonitorService()
        let stream = service.startMonitoring(folder: temporaryFolder)

        let expectedFileURL = temporaryFolder
            .appendingPathComponent("test-model.io")

        let expectation = XCTestExpectation(
            description: "Created file is reported as changed"
        )

        let monitoringTask = Task {
            for await change in stream {
                if case let .changed(changedURL) = change,
                   changedURL.standardizedFileURL
                       == expectedFileURL.standardizedFileURL {
                    expectation.fulfill()
                    return
                }
            }
        }

        fileManager.createFile(
            atPath: expectedFileURL.path,
            contents: Data(),
            attributes: nil
        )

        wait(
            for: [expectation],
            timeout: 5.0
        )

        monitoringTask.cancel()
        service.stopMonitoring()
    }

    func testMonitorReportsModifiedFileAsChanged() async throws {
        let fileManager = FileManager.default
        let temporaryFolder = fileManager.temporaryDirectory
            .appendingPathComponent(
                "BrickViewModelFolderMonitorTest-\(UUID().uuidString)",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(at: temporaryFolder)
        }

        let existingFileURL = temporaryFolder
            .appendingPathComponent("existing-model.io")

        try Data("initial content".utf8).write(
            to: existingFileURL
        )

        let service = ModelFolderMonitorService()
        let stream = service.startMonitoring(folder: temporaryFolder)

        let expectation = XCTestExpectation(
            description: "Modified file is reported as changed"
        )

        let monitoringTask = Task {
            for await change in stream {
                if case let .changed(changedURL) = change,
                   changedURL.standardizedFileURL
                       == existingFileURL.standardizedFileURL {
                    expectation.fulfill()
                    return
                }
            }
        }

        try Data("modified content".utf8).write(
            to: existingFileURL
        )

        wait(
            for: [expectation],
            timeout: 5.0
        )

        monitoringTask.cancel()
        service.stopMonitoring()
    }

    func testMonitorReportsDeletedFileAsRemoved() async throws {
        let fileManager = FileManager.default
        let temporaryFolder = fileManager.temporaryDirectory
            .appendingPathComponent(
                "BrickViewModelFolderMonitorTest-\(UUID().uuidString)",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(at: temporaryFolder)
        }

        let existingFileURL = temporaryFolder
            .appendingPathComponent("existing-model.io")

        let readinessFileURL = temporaryFolder
            .appendingPathComponent("monitor-ready")

        try Data("model content".utf8).write(
            to: existingFileURL
        )

        let service = ModelFolderMonitorService()
        let stream = service.startMonitoring(folder: temporaryFolder)

        let readinessExpectation = XCTestExpectation(
            description: "Folder monitor is receiving events"
        )

        let deletionExpectation = XCTestExpectation(
            description: "Deleted file is reported as removed"
        )

        let monitoringTask: Task<Void, Never> = Task {
            for await change in stream {
                switch change {
                case let .changed(changedURL):
                    if changedURL.standardizedFileURL
                        == readinessFileURL.standardizedFileURL {
                        readinessExpectation.fulfill()
                    }

                case let .removed(changedURL):
                    let actualPath: String = normalizedPath(
                        changedURL
                    )

                    let expectedPath: String = normalizedPath(
                        existingFileURL
                    )

                    if actualPath == expectedPath {
                        deletionExpectation.fulfill()
                        return
                    }
                }
            }
        }

        fileManager.createFile(
            atPath: readinessFileURL.path,
            contents: Data(),
            attributes: nil
        )

        wait(
            for: [readinessExpectation],
            timeout: 5.0
        )

        try fileManager.removeItem(at: existingFileURL)

        wait(
            for: [deletionExpectation],
            timeout: 5.0
        )

        monitoringTask.cancel()
        service.stopMonitoring()
    }

    func testMonitorReportsRenamedFileAsChanged() async throws {
        let fileManager = FileManager.default
        let temporaryFolder = fileManager.temporaryDirectory
            .appendingPathComponent(
                "BrickViewModelFolderMonitorTest-\(UUID().uuidString)",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(at: temporaryFolder)
        }

        let originalFileURL = temporaryFolder
            .appendingPathComponent("original-model.io")

        let renamedFileURL = temporaryFolder
            .appendingPathComponent("renamed-model.io")

        try Data("model content".utf8).write(
            to: originalFileURL
        )

        let service = ModelFolderMonitorService()
        let stream = service.startMonitoring(folder: temporaryFolder)

        let expectation = XCTestExpectation(
            description: "Renamed file is reported as changed"
        )

        let monitoringTask = Task {
            for await change in stream {
                if case let .changed(changedURL) = change,
                   changedURL.standardizedFileURL
                       == renamedFileURL.standardizedFileURL {
                    expectation.fulfill()
                    return
                }
            }
        }

        try fileManager.moveItem(
            at: originalFileURL,
            to: renamedFileURL
        )

        wait(
            for: [expectation],
            timeout: 5.0
        )

        monitoringTask.cancel()
        service.stopMonitoring()
    }

    /// Normalizes macOS temporary-directory paths for comparison.
    ///
    /// macOS exposes /var as a symbolic link to /private/var. FSEvents
    /// reports the canonical /private/var path while FileManager may
    /// return the /var path. The two paths therefore represent the same
    /// file-system location and must be treated as equivalent in tests.
    private func normalizedPath(_ url: URL) -> String {
        let path: String = url.standardizedFileURL.path

        if path.hasPrefix("/private/var/") {
            return String(
                path.dropFirst("/private".count)
            )
        }

        return path
    }
}
