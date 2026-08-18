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
//  its thumbnail, filename, part count, and Studio-inspired hover
//  appearance.
//
//  The thumbnail container is structured so the hover state can be
//  displayed as an overlay without changing the card's size or layout.
//
//  The view does not open files, load model data, generate thumbnails,
//  or manage the model collection.
//

import SwiftUI

struct ModelCardView: View {

    let model: Model
    let sizeDefinition: ThumbnailSizeDefinition

    @State private var isHovering: Bool = false

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
            ThumbnailConfiguration.medium
    ) {
        self.model = model
        self.sizeDefinition = sizeDefinition
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
}
