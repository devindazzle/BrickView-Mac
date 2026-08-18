//
//  ModelContextMenuView.swift
//  BrickView
//
//  Created by Kim Pedersen on 18/08/2026.
//

//
//  Purpose:
//  Displays the custom BrickView context menu for a model card.
//
//  The view is intentionally presentation-only. It does not determine
//  which model is selected or how menu actions are executed.
//
//  The visual design follows BrickView's Studio-inspired dark UI:
//
//  - dark menu surface
//  - subtle border
//  - rounded corners
//  - compact spacing
//  - highlighted menu items on hover
//
//  Native macOS context-menu presentation is intentionally not used.
//

import SwiftUI

struct ModelContextMenuView: View {

    let onRevealInFinder: () -> Void
    let onCopyPath: () -> Void
    let onMenuHoverChanged: (Bool) -> Void

    @State private var hoveredAction:
        ModelContextMenuAction?

    private let menuBackgroundColor: Color =
        Color(
            red: 42.0 / 255.0,
            green: 45.0 / 255.0,
            blue: 52.0 / 255.0
        )

    private let menuBorderColor: Color =
        Color(
            red: 78.0 / 255.0,
            green: 80.0 / 255.0,
            blue: 88.0 / 255.0
        )

    private let menuHoverColor: Color =
        Color(
            red: 64.0 / 255.0,
            green: 67.0 / 255.0,
            blue: 76.0 / 255.0
        )

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            menuItem(
                action: .revealInFinder,
                title: "Reveal in Finder",
                systemImage: "folder",
                actionHandler: onRevealInFinder
            )

            menuItem(
                action: .copyPath,
                title: "Copy Path",
                systemImage: "doc.on.doc",
                actionHandler: onCopyPath
            )
        }
        .padding(5)
        .frame(
            width: 190
        )
        .background(
            RoundedRectangle(
                cornerRadius: 9
            )
            .fill(
                menuBackgroundColor
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 9
            )
            .stroke(
                menuBorderColor,
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.35),
            radius: 12,
            x: 0,
            y: 5
        )
        .onHover { hovering in
            onMenuHoverChanged(hovering)
        }
    }

    private func menuItem(
        action: ModelContextMenuAction,
        title: String,
        systemImage: String,
        actionHandler: @escaping () -> Void
    ) -> some View {
        Button {
            actionHandler()
        } label: {
            HStack(spacing: 9) {
                Image(
                    systemName: systemImage
                )
                .frame(
                    width: 18
                )

                Text(title)

                Spacer()
            }
            .font(
                .system(
                    size: 13
                )
            )
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .frame(
                height: 28
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 6
                )
                .fill(
                    hoveredAction == action
                        ? menuHoverColor
                        : Color.clear
                )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredAction = hovering
                ? action
                : nil
        }
    }
}

private enum ModelContextMenuAction: Equatable {

    case revealInFinder
    case copyPath
}
