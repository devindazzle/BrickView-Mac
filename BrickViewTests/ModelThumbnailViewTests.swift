//
//  ModelThumbnailViewTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 15/08/2026.
//

import SwiftUI
import XCTest
@testable import BrickView

final class ModelThumbnailViewTests: XCTestCase {

    func testValidModelWithThumbnail() throws {
        let bundle = Bundle(for: ModelThumbnailViewTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        let model = Model(
            url: fileURL,
            partCount: 232,
            status: .valid
        )

        let view = ModelThumbnailView(model: model)

        XCTAssertNotNil(view)
    }

    func testValidModelWithoutThumbnail() throws {
        let bundle = Bundle(for: ModelThumbnailViewTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-no-thumbnail",
                withExtension: "io"
            )
        )

        let model = Model(
            url: fileURL,
            partCount: 232,
            status: .valid
        )

        let view = ModelThumbnailView(model: model)

        XCTAssertNotNil(view)
    }

    func testInvalidModel() throws {
        let bundle = Bundle(for: ModelThumbnailViewTests.self)

        let fileURL = try XCTUnwrap(
            bundle.url(
                forResource: "383-knights-tournament-invalid",
                withExtension: "io"
            )
        )

        let model = Model(
            url: fileURL,
            status: .invalid
        )

        let view = ModelThumbnailView(model: model)

        XCTAssertNotNil(view)
    }
}
