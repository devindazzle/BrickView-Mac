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
//  characters. If no wildcard is present, the search behaves as if
//  the search text were surrounded by '*'.
//
//  Search patterns without the .io extension are matched against
//  the filename without its extension. Patterns containing .io are
//  matched against the complete filename.
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

        let searchPattern: String

        if searchText.contains("*") {
            searchPattern = searchText
        } else {
            searchPattern = "*\(searchText)*"
        }

        let shouldMatchCompleteFilename = searchText.contains(".io")
        let regexPattern = makeRegexPattern(from: searchPattern)

        guard let regularExpression = try? NSRegularExpression(
            pattern: regexPattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        return models.filter { model in
            let filename = shouldMatchCompleteFilename
                ? model.filename
                : filenameWithoutExtension(for: model.filename)

            let range = NSRange(
                location: 0,
                length: filename.utf16.count
            )

            return regularExpression.firstMatch(
                in: filename,
                options: [],
                range: range
            ) != nil
        }
    }

    private func filenameWithoutExtension(for filename: String) -> String {
        let url = URL(fileURLWithPath: filename)
        return url.deletingPathExtension().lastPathComponent
    }

    private func makeRegexPattern(from wildcardPattern: String) -> String {
        let components = wildcardPattern
            .split(
                separator: "*",
                omittingEmptySubsequences: false
            )
            .map {
                NSRegularExpression.escapedPattern(
                    for: String($0)
                )
            }

        return "^" + components.joined(separator: ".*") + "$"
    }
}
