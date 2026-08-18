//
//  ModelCardView.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  SwiftUI view responsible for displaying a single BrickView model card.
//
//  The view owns the visual presentation of a model card, including
//  its thumbnail, filename, part count, Studio-inspired hover
//  appearance, and custom BrickView context menu.
//
//  The view does not use the native macOS context-menu presentation.
//  Context-menu visibility is coordinated by ContentView so that only
//  one context menu can be visible at any time.
//

import SwiftUI
import AppKit

struct ModelCardView: View {

    let model: Model
    let sizeDefinition: ThumbnailSizeDefinition
    let isContextMenuVisible: Bool
    let onContextMenuRequested: () -> Void
    let onContextMenuDismissed: () -> Void

    @State private var isHovering: Bool = false
    @State private var contextMenuLocation: CGPoint = .zero

    private let thumbnailBackgroundColor: Color =
        Color(
            red: 36.0 / 255.0,
            green: 37.0 / 255.0,
            blue: 46.0 / 255.0
        )

    private let thumbnailBorderColor: Color =
        Color(
            red: 24.0 / 255.0,
            green: 25.0 / 255.0,
            blue: 29.0 / 255.0
        )

    init(
        model: Model,
        sizeDefinition: ThumbnailSizeDefinition =
            ThumbnailConfiguration.medium,
        isContextMenuVisible: Bool = false,
        onContextMenuRequested: @escaping () -> Void = {},
        onContextMenuDismissed: @escaping () -> Void = {}
    ) {
        self.model = model
        self.sizeDefinition = sizeDefinition
        self.isContextMenuVisible = isContextMenuVisible
        self.onContextMenuRequested = onContextMenuRequested
        self.onContextMenuDismissed = onContextMenuDismissed
    }

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 10
                )
                .fill(
                    thumbnailBackgroundColor
                )

                ModelThumbnailView(
                    model: model,
                    size: sizeDefinition.thumbnailSize
                )
                .frame(
                    width: sizeDefinition.thumbnailSize.width,
                    height: sizeDefinition.thumbnailSize.height
                )

                RoundedRectangle(
                    cornerRadius: 10
                )
                .fill(
                    Color.black.opacity(
                        isHovering ? 0.38 : 0.0
                    )
                )
                .allowsHitTesting(false)
                .animation(
                    .easeOut(duration: 0.15),
                    value: isHovering
                )

                if isContextMenuVisible {
                    ModelContextMenuView(
                        onRevealInFinder: {
                            revealInFinder()
                        },
                        onCopyPath: {
                            copyPath()
                        },
                        onMenuHoverChanged: { hovering in
                            if !hovering {
                                onContextMenuDismissed()
                            }
                        }
                    )
                    .position(
                        x: contextMenuXPosition,
                        y: contextMenuYPosition
                    )
                    .zIndex(10)
                }

                RightClickDetector { location in
                    contextMenuLocation = location
                    onContextMenuRequested()
                }
                .allowsHitTesting(true)
            }
            .frame(
                width: sizeDefinition.thumbnailSize.width,
                height: sizeDefinition.thumbnailSize.height
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 10
                )
                .stroke(
                    thumbnailBorderColor,
                    lineWidth: 1
                )
            )
            .onHover { hovering in
                isHovering = hovering
            }

            Text(model.filename)
                .font(.headline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            if let partCount = model.partCount {
                Text("\(partCount) parts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
        }
        .frame(
            width: sizeDefinition.cardSize.width,
            height: sizeDefinition.cardSize.height,
            alignment: .topLeading
        )
    }

    private var contextMenuXPosition: CGFloat {

        let halfMenuWidth: CGFloat = 95
        let minimumX: CGFloat = halfMenuWidth

        let maximumX: CGFloat =
            sizeDefinition.thumbnailSize.width
                - halfMenuWidth

        return min(
            max(
                contextMenuLocation.x + halfMenuWidth,
                minimumX
            ),
            maximumX
        )
    }

    private var contextMenuYPosition: CGFloat {

        let menuHeight: CGFloat = 76
        let halfMenuHeight: CGFloat =
            menuHeight / 2

        let minimumY: CGFloat =
            halfMenuHeight

        let maximumY: CGFloat =
            sizeDefinition.thumbnailSize.height
                - halfMenuHeight

        return min(
            max(
                contextMenuLocation.y + halfMenuHeight,
                minimumY
            ),
            maximumY
        )
    }

    private func revealInFinder() {

        NSWorkspace.shared.activateFileViewerSelecting(
            [model.id]
        )

        onContextMenuDismissed()
    }

    private func copyPath() {

        NSPasteboard.general.clearContents()

        NSPasteboard.general.setString(
            model.id.path,
            forType: .string
        )

        onContextMenuDismissed()
    }
}
