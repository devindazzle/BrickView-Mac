//
//  ModelBrowserCoordinatorTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 18/08/2026.
//

//
//  Purpose:
//  Verifies the model collection update behaviour of
//  ModelBrowserCoordinator.
//
//  These tests intentionally exercise the coordinator's model
//  collection operations. They also verify that model identity remains
//  stable when macOS exposes the same filesystem location through
//  different /var and /private/var path representations.
//

import XCTest
@testable import BrickView

@MainActor
final class ModelBrowserCoordinatorTests: XCTestCase {

    func testUpsertModelAddsNewModel() {
        let coordinator = ModelBrowserCoordinator()

        let modelURL = URL(
            fileURLWithPath: "/tmp/new-model.io"
        )

        let model = Model(
            url: modelURL,
            partCount: 100,
            modificationDate: Date(),
            status: .valid
        )

        coordinator.upsertModel(
            model
        )

        XCTAssertEqual(
            coordinator.models.count,
            1
        )

        XCTAssertEqual(
            coordinator.models.first?.id,
            modelURL
        )

        XCTAssertEqual(
            coordinator.models.first?.partCount,
            100
        )
    }

    func testUpsertModelReplacesExistingModel() {
        let coordinator = ModelBrowserCoordinator()

        let modelURL = URL(
            fileURLWithPath: "/tmp/existing-model.io"
        )

        let originalDate = Date(
            timeIntervalSince1970: 1_000
        )

        let updatedDate = Date(
            timeIntervalSince1970: 2_000
        )

        let originalModel = Model(
            url: modelURL,
            partCount: 100,
            modificationDate: originalDate,
            status: .valid
        )

        let updatedModel = Model(
            url: modelURL,
            partCount: 125,
            modificationDate: updatedDate,
            status: .valid
        )

        coordinator.upsertModel(
            originalModel
        )

        coordinator.upsertModel(
            updatedModel
        )

        XCTAssertEqual(
            coordinator.models.count,
            1
        )

        XCTAssertEqual(
            coordinator.models.first?.id,
            modelURL
        )

        XCTAssertEqual(
            coordinator.models.first?.partCount,
            125
        )

        XCTAssertEqual(
            coordinator.models.first?.modificationDate,
            updatedDate
        )
    }

    func testRemoveModelRemovesMatchingModel() {
        let coordinator = ModelBrowserCoordinator()

        let firstModelURL = URL(
            fileURLWithPath: "/tmp/first-model.io"
        )

        let secondModelURL = URL(
            fileURLWithPath: "/tmp/second-model.io"
        )

        let firstModel = Model(
            url: firstModelURL,
            partCount: 100,
            status: .valid
        )

        let secondModel = Model(
            url: secondModelURL,
            partCount: 200,
            status: .valid
        )

        coordinator.upsertModel(
            firstModel
        )

        coordinator.upsertModel(
            secondModel
        )

        coordinator.removeModel(
            with: firstModelURL
        )

        XCTAssertEqual(
            coordinator.models.count,
            1
        )

        XCTAssertEqual(
            coordinator.models.first?.id,
            secondModelURL
        )

        XCTAssertEqual(
            coordinator.models.first?.partCount,
            200
        )
    }

    func testRemoveModelHandlesVarPathRepresentationDifferences() {
        let coordinator = ModelBrowserCoordinator()

        let modelURL = URL(
            fileURLWithPath:
                "/var/folders/test-folder/test-model.io"
        )

        let removalURL = URL(
            fileURLWithPath:
                "/private/var/folders/test-folder/test-model.io"
        )

        let model = Model(
            url: modelURL,
            partCount: 100,
            status: .valid
        )

        coordinator.upsertModel(
            model
        )

        coordinator.removeModel(
            with: removalURL
        )

        XCTAssertTrue(
            coordinator.models.isEmpty
        )
    }
}
