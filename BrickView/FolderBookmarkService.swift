//
//  FolderBookmarkService.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Persists access to a user-selected folder using a security-scoped
//  bookmark so the folder can be accessed again after application restart.
//
//  The service does not present UI, select folders, or manage the
//  lifetime of security-scoped resource access.
//

import Foundation

struct FolderBookmarkService {
    private let userDefaults: UserDefaults

    private let bookmarkKey = "selectedFolderBookmark"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveBookmark(for folder: URL) throws {
        let bookmarkData = try folder.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        userDefaults.set(bookmarkData, forKey: bookmarkKey)
    }

    func restoreFolder() -> URL? {
        guard let bookmarkData = userDefaults.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false

        guard let folder = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            clearBookmark()
            return nil
        }

        if isStale {
            try? saveBookmark(for: folder)
        }

        return folder
    }

    func clearBookmark() {
        userDefaults.removeObject(forKey: bookmarkKey)
    }
}
