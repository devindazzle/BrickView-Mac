//
//  WindowConfigurator.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {

    private let windowPersistenceService = WindowPersistenceService()

    func makeNSView(context: Context) -> NSView {

        let view = NSView()

        DispatchQueue.main.async {
            configureWindow(for: view)
        }

        return view
    }

    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {

        DispatchQueue.main.async {
            configureWindow(for: nsView)
        }
    }

    private func configureWindow(for view: NSView) {

        guard let window = view.window else {
            return
        }

        window.contentMaxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        restoreWindowFrameIfNeeded(for: window)
        installWindowFramePersistence(for: window)
    }

    private func restoreWindowFrameIfNeeded(
        for window: NSWindow
    ) {

        guard !window.frameAutosaveName.isEmpty else {
            let restoredFrame =
                windowPersistenceService.restoreFrame(
                    defaultSize: window.frame.size
                )

            window.setFrame(
                restoredFrame,
                display: true
            )

            return
        }
    }

    private func installWindowFramePersistence(
        for window: NSWindow
    ) {

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [windowPersistenceService] notification in

            guard let window =
                notification.object as? NSWindow else {
                return
            }

            windowPersistenceService.save(
                frame: window.frame
            )
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [windowPersistenceService] notification in

            guard let window =
                notification.object as? NSWindow else {
                return
            }

            windowPersistenceService.save(
                frame: window.frame
            )
        }
    }
}
