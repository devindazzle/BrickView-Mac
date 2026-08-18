//
//  RightClickDetector.swift
//  BrickView
//
//  Created by Kim Pedersen on 18/08/2026.
//

//
//  Purpose:
//  Detects right mouse button clicks inside a SwiftUI view.
//
//  SwiftUI's native context-menu presentation is intentionally not used
//  by BrickView because the application uses its own custom context menu.
//  This NSViewRepresentable bridges the macOS right-mouse event into
//  SwiftUI and reports the click location in the local view coordinates.
//

import AppKit
import SwiftUI

struct RightClickDetector: NSViewRepresentable {

    let onRightClick: (CGPoint) -> Void

    func makeNSView(
        context: Context
    ) -> RightClickTrackingView {
        let view = RightClickTrackingView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(
        _ nsView: RightClickTrackingView,
        context: Context
    ) {
        nsView.onRightClick = onRightClick
    }
}

final class RightClickTrackingView: NSView {

    var onRightClick: ((CGPoint) -> Void)?

    override func rightMouseDown(
        with event: NSEvent
    ) {
        let location = convert(
            event.locationInWindow,
            from: nil
        )

        onRightClick?(
            location
        )
    }
}
