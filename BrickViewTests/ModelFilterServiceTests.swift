//
//  ModelFilterServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 16/08/2026.
//

import XCTest
@testable import BrickView

final class ModelFilterServiceTests: XCTestCase {

    private let service = ModelFilterService()

    private let models = [
        Model(
            url: URL(fileURLWithPath: "/Models/my-castle-test.io")
        ),
        Model(
            url: URL(fileURLWithPath: "/Models/castle-house.io")
        ),
        Model(
            url: URL(fileURLWithPath: "/Models/my-old-castle.io")
        ),
        Model(
            url: URL(fileURLWithPath: "/Models/castle.io")
        ),
        Model(
            url: URL(fileURLWithPath: "/Models/knights-castle.io")
        ),
        Model(
            url: URL(fileURLWithPath: "/Models/space-station.io")
        )
    ]

    func testSearchWithoutWildcardMatchesSubstringCaseInsensitively() {

        let filteredModels = service.filter(
            models,
            matching: "CASTLE"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "my-castle-test.io",
                "castle-house.io",
                "my-old-castle.io",
                "castle.io",
                "knights-castle.io"
            ]
        )
    }

    func testWildcardAtEndRequiresPrefixMatch() {

        let filteredModels = service.filter(
            models,
            matching: "castle*"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "castle-house.io",
                "castle.io"
            ]
        )
    }

    func testWildcardAtBeginningRequiresSuffixMatch() {

        let filteredModels = service.filter(
            models,
            matching: "*castle"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "my-old-castle.io",
                "castle.io",
                "knights-castle.io"
            ]
        )
    }

    func testWildcardAtBothEndsMatchesSubstring() {

        let filteredModels = service.filter(
            models,
            matching: "*castle*"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "my-castle-test.io",
                "castle-house.io",
                "my-old-castle.io",
                "castle.io",
                "knights-castle.io"
            ]
        )
    }

    func testWildcardCanAppearInTheMiddleOfPattern() {

        let filteredModels = service.filter(
            models,
            matching: "castle*house"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "castle-house.io"
            ]
        )
    }

    func testWildcardPatternCanRequirePrefixAndSuffix() {

        let filteredModels = service.filter(
            models,
            matching: "kni*cas*le"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "knights-castle.io"
            ]
        )
    }

    func testWildcardPatternRequiresSearchPartsInOrder() {

        let filteredModels = service.filter(
            models,
            matching: "cas*kni"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            []
        )
    }

    func testSearchIncludingExtensionMatchesSubstring() {

        let filteredModels = service.filter(
            models,
            matching: "castle.io"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            [
                "my-old-castle.io",
                "castle.io",
                "knights-castle.io"
            ]
        )
    }

    func testSingleWildcardMatchesAllModels() {

        let filteredModels = service.filter(
            models,
            matching: "*"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            models.map { $0.filename }
        )
    }

    func testMultipleWildcardsWithoutSearchTextMatchAllModels() {

        let filteredModels = service.filter(
            models,
            matching: "***"
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            models.map { $0.filename }
        )
    }

    func testEmptySearchReturnsAllModels() {

        let filteredModels = service.filter(
            models,
            matching: ""
        )

        XCTAssertEqual(
            filteredModels.map { $0.filename },
            models.map { $0.filename }
        )
    }
}
