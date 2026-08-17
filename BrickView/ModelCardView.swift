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
//  its preview area, filename, and part count. It should not be
//  responsible for loading files, generating thumbnails, or managing
//  the model collection.
//

import SwiftUI

struct ModelCardView: View {
    let model: Model
    let sizeDefinition: ThumbnailSizeDefinition

    init(
        model: Model,
        sizeDefinition: ThumbnailSizeDefinition = ThumbnailConfiguration.medium
    ) {
        self.model = model
        self.sizeDefinition = sizeDefinition
    }

    var body: some View {
        VStack {
            ModelThumbnailView(
                model: model,
                size: sizeDefinition.thumbnailSize
            )
            .frame(
                width: sizeDefinition.thumbnailSize.width,
                height: sizeDefinition.thumbnailSize.height
            )
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )

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
