//
//  WindowPersistenceService.swift
//  BrickView
//
//  Created by Kim Pedersen on 18/08/2026.
//

//
//  Purpose:
//  Persists and restores the BrickView window frame.
//
//  The service stores the window's size and position in UserDefaults
//  and validates a saved frame against the currently visible screen
//  areas before restoring it.
//
//  If the saved frame is missing or no longer fits an available display,
//  a centered fallback frame is returned using the supplied default size.
//  The service is UI-independent and does not own or manipulate an
//  NSWindow directly.
//

import AppKit

struct WindowPersistenceService {

    private let defaults: UserDefaults
    private let defaultsKey: String
    private let screenFramesProvider: () -> [CGRect]

    init(
        defaults: UserDefaults = .standard,
        defaultsKey: String = "BrickView.WindowFrame",
        screenFramesProvider: @escaping () -> [CGRect] = {
            NSScreen.screens.map { $0.visibleFrame }
        }
    ) {
        self.defaults = defaults
        self.defaultsKey = defaultsKey
        self.screenFramesProvider = screenFramesProvider
    }

    func save(frame: CGRect) {
        defaults.set(
            NSStringFromRect(frame),
            forKey: defaultsKey
        )
    }

    func restoreFrame(
        defaultSize: CGSize
    ) -> CGRect {

        let visibleFrames = screenFramesProvider()

        guard !visibleFrames.isEmpty else {
            return fallbackFrame(
                size: defaultSize,
                visibleFrame: CGRect(
                    x: 0,
                    y: 0,
                    width: 1440,
                    height: 900
                )
            )
        }

        if let savedFrame = savedFrame(),
           let validVisibleFrame = visibleFrames.first(
               where: { $0.contains(savedFrame) }
           ) {
            return constrain(
                savedFrame,
                to: validVisibleFrame
            )
        }

        return fallbackFrame(
            size: defaultSize,
            visibleFrame: visibleFrames[0]
        )
    }

    private func savedFrame() -> CGRect? {

        guard let savedFrameString =
            defaults.string(forKey: defaultsKey) else {
            return nil
        }

        return NSRectFromString(savedFrameString)
    }

    private func fallbackFrame(
        size: CGSize,
        visibleFrame: CGRect
    ) -> CGRect {

        let width = min(
            size.width,
            visibleFrame.width
        )

        let height = min(
            size.height,
            visibleFrame.height
        )

        return CGRect(
            x: visibleFrame.midX - (width / 2),
            y: visibleFrame.midY - (height / 2),
            width: width,
            height: height
        )
    }

    private func constrain(
        _ frame: CGRect,
        to visibleFrame: CGRect
    ) -> CGRect {

        var constrainedFrame = frame

        if constrainedFrame.width > visibleFrame.width {
            constrainedFrame.size.width = visibleFrame.width
        }

        if constrainedFrame.height > visibleFrame.height {
            constrainedFrame.size.height = visibleFrame.height
        }

        if constrainedFrame.minX < visibleFrame.minX {
            constrainedFrame.origin.x = visibleFrame.minX
        }

        if constrainedFrame.maxX > visibleFrame.maxX {
            constrainedFrame.origin.x =
                visibleFrame.maxX - constrainedFrame.width
        }

        if constrainedFrame.minY < visibleFrame.minY {
            constrainedFrame.origin.y = visibleFrame.minY
        }

        if constrainedFrame.maxY > visibleFrame.maxY {
            constrainedFrame.origin.y =
                visibleFrame.maxY - constrainedFrame.height
        }

        return constrainedFrame
    }
}
