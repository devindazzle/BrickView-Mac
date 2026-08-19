//
//  WindowConfigurator.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Configures the native macOS window used by BrickView.
//
//  The configurator bridges SwiftUI to NSWindow and is responsible for
//  window-specific configuration that cannot be handled directly by
//  SwiftUI. Window size and position persistence is delegated to
//  WindowPersistenceService.
//
//  Window lifecycle observers are installed only once for each window
//  and are removed when the configurator's coordinator is released.
//

import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {

        let view = NSView()

        DispatchQueue.main.async {
            configureWindow(
                for: view,
                coordinator: context.coordinator
            )
        }

        return view
    }

    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {

        DispatchQueue.main.async {
            configureWindow(
                for: nsView,
                coordinator: context.coordinator
            )
        }
    }

    private func configureWindow(
        for view: NSView,
        coordinator: Coordinator
    ) {

        guard let window = view.window else {
            return
        }

        window.contentMaxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        guard coordinator.configuredWindow !== window else {
            return
        }

        coordinator.configure(
            window: window
        )
    }

    final class Coordinator {

        private let windowPersistenceService =
            WindowPersistenceService()

        private var observerTokens: [NSObjectProtocol] = []

        weak var configuredWindow: NSWindow?

        func configure(window: NSWindow) {

            removeObservers()

            configuredWindow = window

            restoreWindowFrameIfNeeded(
                for: window
            )

            installWindowFramePersistence(
                for: window
            )
        }

        private func restoreWindowFrameIfNeeded(
            for window: NSWindow
        ) {

            guard window.frameAutosaveName.isEmpty else {
                return
            }

            let restoredFrame =
                windowPersistenceService.restoreFrame(
                    defaultSize: window.frame.size
                )

            window.setFrame(
                restoredFrame,
                display: true
            )
        }

        private func installWindowFramePersistence(
            for window: NSWindow
        ) {

            let moveObserver =
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: window,
                    queue: .main
                ) { [weak self] notification in

                    guard let self,
                          let window =
                            notification.object as? NSWindow else {
                        return
                    }

                    self.windowPersistenceService.save(
                        frame: window.frame
                    )
                }

            let resizeObserver =
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: .main
                ) { [weak self] notification in

                    guard let self,
                          let window =
                            notification.object as? NSWindow else {
                        return
                    }

                    self.windowPersistenceService.save(
                        frame: window.frame
                    )
                }

            observerTokens = [
                moveObserver,
                resizeObserver
            ]
        }

        private func removeObservers() {

            for observerToken in observerTokens {
                NotificationCenter.default.removeObserver(
                    observerToken
                )
            }

            observerTokens.removeAll()
        }

        deinit {
            removeObservers()
        }
    }
}
