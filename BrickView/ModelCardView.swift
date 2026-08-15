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
    let filename: String
    let partCount: Int

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .frame(width: 360, height: 220)
                .overlay {
                    Text("Model Preview")
                        .foregroundColor(.secondary)
                }

            Text(filename)
                .font(.headline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Text("\(partCount) parts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .frame(width: 360)
    }
}
