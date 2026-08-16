//
//  FolderAccessSession.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Owns the lifetime of security-scoped access to a user-selected folder.
//
//  The session starts security-scoped access when created and stops that
//  access automatically when the session is released.
//

import Foundation

final class FolderAccessSession {
    let folder: URL

    init?(folder: URL) {
        guard folder.startAccessingSecurityScopedResource() else {
            return nil
        }

        self.folder = folder
    }

    deinit {
        folder.stopAccessingSecurityScopedResource()
    }
}
