//
//  ModelFilterService.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Filters BrickView models using a case-insensitive filename search.
//
//  A '*' character is treated as a wildcard matching zero or more
//  characters.
//
//  If no wildcard is present, the search behaves as a case-insensitive
//  substring search.
//
//  Wildcard searches are matched against the filename without the
//  .io extension.
//
//  A wildcard at the beginning requires the pattern to match the end
//  of the filename.
//
//  A wildcard at the end requires the pattern to match the beginning
//  of the filename.
//
//  Wildcards between search terms allow any number of characters between
//  those terms.
//

import Foundation

struct ModelFilterService {

    func filter(
        _ models: [Model],
        matching searchText: String
    ) -> [Model] {

        guard !searchText.isEmpty else {
            return models
        }

        return models.filter { model in
            matches(
                filename: model.filename,
                searchText: searchText
            )
        }
    }

    private func matches(
        filename: String,
        searchText: String
    ) -> Bool {

        let normalizedSearchText = searchText.lowercased()

        guard normalizedSearchText.contains("*") else {
            return filename.lowercased().contains(normalizedSearchText)
        }

        let searchableFilename = filenameWithoutExtension(
            for: filename
        ).lowercased()

        let startsWithWildcard = normalizedSearchText.first == "*"
        let endsWithWildcard = normalizedSearchText.last == "*"

        let searchParts = normalizedSearchText
            .split(
                separator: "*",
                omittingEmptySubsequences: true
            )
            .map(String.init)

        guard !searchParts.isEmpty else {
            return true
        }

        if !startsWithWildcard && !endsWithWildcard {
            return matchesMiddleWildcardPattern(
                filename: searchableFilename,
                searchParts: searchParts
            )
        }

        if startsWithWildcard && endsWithWildcard {
            return matchesAnywherePattern(
                filename: searchableFilename,
                searchParts: searchParts
            )
        }

        if endsWithWildcard {
            return matchesPrefixPattern(
                filename: searchableFilename,
                searchParts: searchParts
            )
        }

        return matchesSuffixPattern(
            filename: searchableFilename,
            searchParts: searchParts
        )
    }

    private func filenameWithoutExtension(
        for filename: String
    ) -> String {

        let url = URL(fileURLWithPath: filename)

        return url.deletingPathExtension().lastPathComponent
    }

    private func matchesPrefixPattern(
        filename: String,
        searchParts: [String]
    ) -> Bool {

        guard let firstSearchPart = searchParts.first else {
            return true
        }

        guard filename.hasPrefix(firstSearchPart) else {
            return false
        }

        return matchesRemainingParts(
            filename: filename,
            searchParts: Array(searchParts.dropFirst()),
            startingAfter: firstSearchPart.endIndex
        )
    }

    private func matchesSuffixPattern(
        filename: String,
        searchParts: [String]
    ) -> Bool {

        guard let lastSearchPart = searchParts.last else {
            return true
        }

        guard filename.hasSuffix(lastSearchPart) else {
            return false
        }

        guard searchParts.count > 1 else {
            return true
        }

        let prefixParts = Array(searchParts.dropLast())
        let suffixStartIndex = filename.index(
            filename.endIndex,
            offsetBy: -lastSearchPart.count
        )

        return matchesRemainingParts(
            filename: filename,
            searchParts: prefixParts,
            startingAfter: filename.startIndex,
            endingBefore: suffixStartIndex
        )
    }

    private func matchesMiddleWildcardPattern(
        filename: String,
        searchParts: [String]
    ) -> Bool {

        guard let firstSearchPart = searchParts.first else {
            return true
        }

        guard let firstRange = filename.range(
            of: firstSearchPart
        ) else {
            return false
        }

        return matchesRemainingParts(
            filename: filename,
            searchParts: Array(searchParts.dropFirst()),
            startingAfter: firstRange.upperBound
        )
    }

    private func matchesAnywherePattern(
        filename: String,
        searchParts: [String]
    ) -> Bool {

        return matchesRemainingParts(
            filename: filename,
            searchParts: searchParts,
            startingAfter: filename.startIndex
        )
    }

    private func matchesRemainingParts(
        filename: String,
        searchParts: [String],
        startingAfter startIndex: String.Index
    ) -> Bool {

        matchesRemainingParts(
            filename: filename,
            searchParts: searchParts,
            startingAfter: startIndex,
            endingBefore: filename.endIndex
        )
    }

    private func matchesRemainingParts(
        filename: String,
        searchParts: [String],
        startingAfter startIndex: String.Index,
        endingBefore endIndex: String.Index
    ) -> Bool {

        var searchPosition = startIndex

        for searchPart in searchParts {
            let searchRange = searchPosition..<endIndex

            guard let matchRange = filename.range(
                of: searchPart,
                range: searchRange
            ) else {
                return false
            }

            searchPosition = matchRange.upperBound
        }

        return true
    }
}
