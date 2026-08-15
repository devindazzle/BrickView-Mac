//
//  FolderPickerService.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Provides native macOS folder selection for BrickView.
//
//  The service is responsible for interacting with AppKit's
//  NSOpenPanel to let the user select a single folder.
//
//  It does not manage application state, load model files,
//  or update the user interface.
//

import AppKit

struct FolderPickerService {
    func selectFolder() -> URL? {
        let panel = NSOpenPanel()

        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }
}
