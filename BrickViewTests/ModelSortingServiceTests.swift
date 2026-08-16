//
//  ModelSortingServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 16/08/2026.
//

import XCTest
@testable import BrickView

final class ModelSortingServiceTests: XCTestCase {

    func testSortsModelsByFilenameAscending() {
        let models = [
            Model(url: URL(fileURLWithPath: "/Models/Zebra.io")),
            Model(url: URL(fileURLWithPath: "/Models/Alpha.io")),
            Model(url: URL(fileURLWithPath: "/Models/Brick.io"))
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .filename,
            order: .ascending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Alpha.io",
                "Brick.io",
                "Zebra.io"
            ]
        )
    }

    func testSortsModelsByFilenameDescending() {
        let models = [
            Model(url: URL(fileURLWithPath: "/Models/Alpha.io")),
            Model(url: URL(fileURLWithPath: "/Models/Zebra.io")),
            Model(url: URL(fileURLWithPath: "/Models/Brick.io"))
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .filename,
            order: .descending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Zebra.io",
                "Brick.io",
                "Alpha.io"
            ]
        )
    }

    func testSortsModelsByCreationDateAscending() {
        let oldestDate = Date(timeIntervalSince1970: 100)
        let newestDate = Date(timeIntervalSince1970: 300)
        let middleDate = Date(timeIntervalSince1970: 200)

        let models = [
            Model(
                url: URL(fileURLWithPath: "/Models/Newest.io"),
                creationDate: newestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Oldest.io"),
                creationDate: oldestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Middle.io"),
                creationDate: middleDate
            )
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .creationDate,
            order: .ascending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Oldest.io",
                "Middle.io",
                "Newest.io"
            ]
        )
    }

    func testSortsModelsByCreationDateDescending() {
        let oldestDate = Date(timeIntervalSince1970: 100)
        let newestDate = Date(timeIntervalSince1970: 300)
        let middleDate = Date(timeIntervalSince1970: 200)

        let models = [
            Model(
                url: URL(fileURLWithPath: "/Models/Oldest.io"),
                creationDate: oldestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Newest.io"),
                creationDate: newestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Middle.io"),
                creationDate: middleDate
            )
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .creationDate,
            order: .descending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Newest.io",
                "Middle.io",
                "Oldest.io"
            ]
        )
    }

    func testSortsModelsByModificationDateAscending() {
        let oldestDate = Date(timeIntervalSince1970: 100)
        let newestDate = Date(timeIntervalSince1970: 300)
        let middleDate = Date(timeIntervalSince1970: 200)

        let models = [
            Model(
                url: URL(fileURLWithPath: "/Models/Newest.io"),
                modificationDate: newestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Oldest.io"),
                modificationDate: oldestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Middle.io"),
                modificationDate: middleDate
            )
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .modificationDate,
            order: .ascending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Oldest.io",
                "Middle.io",
                "Newest.io"
            ]
        )
    }

    func testSortsModelsByModificationDateDescending() {
        let oldestDate = Date(timeIntervalSince1970: 100)
        let newestDate = Date(timeIntervalSince1970: 300)
        let middleDate = Date(timeIntervalSince1970: 200)

        let models = [
            Model(
                url: URL(fileURLWithPath: "/Models/Oldest.io"),
                modificationDate: oldestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Newest.io"),
                modificationDate: newestDate
            ),
            Model(
                url: URL(fileURLWithPath: "/Models/Middle.io"),
                modificationDate: middleDate
            )
        ]

        let service = ModelSortingService()

        let sortedModels = service.sort(
            models,
            by: .modificationDate,
            order: .descending
        )

        XCTAssertEqual(
            sortedModels.map { $0.filename },
            [
                "Newest.io",
                "Middle.io",
                "Oldest.io"
            ]
        )
    }
}
