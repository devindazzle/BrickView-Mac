//
//  WindowPersistenceServiceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 18/08/2026.
//

import XCTest
@testable import BrickView

final class WindowPersistenceServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private let defaultsSuiteName = "WindowPersistenceServiceTests"

    override func setUp() {
        super.setUp()

        defaults = UserDefaults(
            suiteName: defaultsSuiteName
        )

        defaults.removePersistentDomain(
            forName: defaultsSuiteName
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(
            forName: defaultsSuiteName
        )

        defaults = nil

        super.tearDown()
    }

    func testSavedFrameCanBeRestored() {

        let visibleFrame = CGRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )

        let savedFrame = CGRect(
            x: 100,
            y: 150,
            width: 800,
            height: 600
        )

        let service = WindowPersistenceService(
            defaults: defaults,
            screenFramesProvider: {
                [visibleFrame]
            }
        )

        service.save(frame: savedFrame)

        let restoredFrame = service.restoreFrame(
            defaultSize: CGSize(
                width: 1200,
                height: 800
            )
        )

        XCTAssertEqual(
            restoredFrame,
            savedFrame
        )
    }

    func testInvalidSavedFrameUsesCenteredFallback() {

        let visibleFrame = CGRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )

        let invalidFrame = CGRect(
            x: -500,
            y: -300,
            width: 800,
            height: 600
        )

        let service = WindowPersistenceService(
            defaults: defaults,
            screenFramesProvider: {
                [visibleFrame]
            }
        )

        service.save(frame: invalidFrame)

        let restoredFrame = service.restoreFrame(
            defaultSize: CGSize(
                width: 1200,
                height: 800
            )
        )

        let expectedFrame = CGRect(
            x: 120,
            y: 50,
            width: 1200,
            height: 800
        )

        XCTAssertEqual(
            restoredFrame,
            expectedFrame
        )
    }

    func testSavedFramePartiallyOutsideScreenUsesFallback() {

        let visibleFrame = CGRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )

        let partiallyOutsideFrame = CGRect(
            x: 1000,
            y: 150,
            width: 600,
            height: 500
        )

        let service = WindowPersistenceService(
            defaults: defaults,
            screenFramesProvider: {
                [visibleFrame]
            }
        )

        service.save(frame: partiallyOutsideFrame)

        let restoredFrame = service.restoreFrame(
            defaultSize: CGSize(
                width: 1000,
                height: 700
            )
        )

        let expectedFrame = CGRect(
            x: 220,
            y: 100,
            width: 1000,
            height: 700
        )

        XCTAssertEqual(
            restoredFrame,
            expectedFrame
        )
    }

    func testSavedFrameOnSecondScreenIsRestored() {

        let firstScreen = CGRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )

        let secondScreen = CGRect(
            x: 1440,
            y: 0,
            width: 1920,
            height: 1080
        )

        let savedFrame = CGRect(
            x: 1600,
            y: 100,
            width: 800,
            height: 600
        )

        let service = WindowPersistenceService(
            defaults: defaults,
            screenFramesProvider: {
                [
                    firstScreen,
                    secondScreen
                ]
            }
        )

        service.save(frame: savedFrame)

        let restoredFrame = service.restoreFrame(
            defaultSize: CGSize(
                width: 1200,
                height: 800
            )
        )

        XCTAssertEqual(
            restoredFrame,
            savedFrame
        )
    }

    func testMissingSavedFrameUsesCenteredFallback() {

        let visibleFrame = CGRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )

        let service = WindowPersistenceService(
            defaults: defaults,
            screenFramesProvider: {
                [visibleFrame]
            }
        )

        let restoredFrame = service.restoreFrame(
            defaultSize: CGSize(
                width: 1000,
                height: 700
            )
        )

        let expectedFrame = CGRect(
            x: 220,
            y: 100,
            width: 1000,
            height: 700
        )

        XCTAssertEqual(
            restoredFrame,
            expectedFrame
        )
    }
}
