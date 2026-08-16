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

    var body: some View {
        VStack {
            ModelThumbnailView(model: model)
                .frame(
                    width: ThumbnailConfiguration.displaySize.width,
                    height: ThumbnailConfiguration.displaySize.height
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
            width: ThumbnailConfiguration.displaySize.width
        )
    }
}
