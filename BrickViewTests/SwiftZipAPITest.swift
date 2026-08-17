//
//  SwiftZipPerformanceTests.swift
//  BrickViewTests
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Benchmarks SwiftZip 0.0.5 entry-level ZIP reading for BrickView.
//
//  This is temporary diagnostic code used to compare SwiftZip
//  performance against the existing ZIPFoundation implementation.
//

import XCTest
import SwiftZip

final class SwiftZipPerformanceTests: XCTestCase {
    private let testModelFolder = URL(
        fileURLWithPath: "/Users/kim/Dropbox/LEGO/Brick Link Studio",
        isDirectory: true
    )

    private let legacyPassword = "soho0909"

    func testNormalIOInfoPerformance() throws {
        let fileURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        var elapsedTimes: [TimeInterval] = []

        for _ in 0..<5 {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = try readEntry(
                from: fileURL,
                filename: ".info"
            )

            elapsedTimes.append(
                CFAbsoluteTimeGetCurrent() - startTime
            )
        }

        printPerformance(
            label: "SwiftZip normal .io → .info",
            times: elapsedTimes
        )
    }

    func testNormalIOThumbnailPerformance() throws {
        let fileURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "383-knights-tournament",
                withExtension: "io"
            )
        )

        var elapsedTimes: [TimeInterval] = []

        for _ in 0..<5 {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = try readEntry(
                from: fileURL,
                filename: "thumbnail.png"
            )

            elapsedTimes.append(
                CFAbsoluteTimeGetCurrent() - startTime
            )
        }

        printPerformance(
            label: "SwiftZip normal .io → thumbnail.png",
            times: elapsedTimes
        )
    }

    func testLegacyPasswordProtectedThumbnailPerformance() throws {
        let fileURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "MOC-41818_dandelbaum_Large tower connection 6085-6059",
                withExtension: "io"
            )
        )

        var elapsedTimes: [TimeInterval] = []

        for _ in 0..<5 {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = try readEntry(
                from: fileURL,
                filename: "thumbnail.png",
                password: legacyPassword
            )

            elapsedTimes.append(
                CFAbsoluteTimeGetCurrent() - startTime
            )
        }

        printPerformance(
            label: "SwiftZip legacy password .io → thumbnail.png",
            times: elapsedTimes
        )
    }

    func testLargeFolderInfoPerformance() throws {
        let fileManager = FileManager.default

        let modelURLs = try fileManager.contentsOfDirectory(
            at: testModelFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter {
            $0.pathExtension.lowercased() == "io"
        }

        XCTAssertGreaterThan(
            modelURLs.count,
            100,
            "Expected a large test folder containing more than 100 .io files."
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        for modelURL in modelURLs {
            _ = try readEntry(
                from: modelURL,
                filename: ".info"
            )
        }

        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime

        print(
            """
            SwiftZip large-folder diagnostic:
              .io files: \(modelURLs.count)
              total time: \(elapsedTime) seconds
              average per file: \(elapsedTime / Double(modelURLs.count)) seconds
            """
        )
    }

    private func readEntry(
        from fileURL: URL,
        filename: String,
        password: String? = nil
    ) throws -> Int {
        let archive = try ZipArchive(
            url: fileURL
        )

        let reader = try archive.open(
            filename: filename,
            password: password
        )

        defer {
            reader.close()
        }

        var buffer = [UInt8](
            repeating: 0,
            count: 64 * 1024
        )

        var totalBytesRead: Int = 0

        while true {
            let bytesRead = try buffer.withUnsafeMutableBytes { rawBuffer in
                try reader.read(
                    buf: rawBuffer
                )
            }

            if bytesRead <= 0 {
                break
            }

            totalBytesRead += bytesRead
        }

        return totalBytesRead
    }

    private func printPerformance(
        label: String,
        times: [TimeInterval]
    ) {
        let minimum = times.min() ?? 0
        let maximum = times.max() ?? 0
        let average = times.reduce(0, +) / Double(times.count)

        print(
            """
            SwiftZip performance diagnostic:
              \(label)
              iterations: \(times.count)
              minimum: \(minimum) seconds
              maximum: \(maximum) seconds
              average: \(average) seconds
            """
        )
    }
}
