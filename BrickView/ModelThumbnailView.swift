//
//  ModelThumbnailView.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Displays the thumbnail associated with a BrickView model.
//
//  The view loads thumbnail data asynchronously through
//  ThumbnailLoader and provides explicit fallback states
//  for missing thumbnails and loading errors.
//

import SwiftUI
import AppKit
import CoreGraphics

struct ModelThumbnailView: View {
    let model: Model

    @State private var state: ThumbnailState = .loading

    private let thumbnailLoader = ThumbnailLoader.shared

    var body: some View {
        Group {
            if model.status == .invalid {
                fallbackView(text: "Not valid")
            } else {
                switch state {
                case .loading:
                    ProgressView()

                case .loaded(let image):
                    Image(
                        decorative: image,
                        scale: 1.0
                    )
                    .resizable()
                    .scaledToFit()

                case .noThumbnail:
                    fallbackView(text: "No thumbnail")

                case .error:
                    fallbackView(text: "Unable to load")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: model.id) {
            await loadThumbnail()
        }
    }

    @MainActor
    private func loadThumbnail() async {
        guard model.status == .valid else {
            return
        }

        state = .loading

        do {
            let result = try await thumbnailLoader.load(
                for: model.id,
                size: ThumbnailConfiguration.displaySize,
                priority: .high
            )

            guard !Task.isCancelled else {
                return
            }

            switch result {
            case .loaded(let image):
                state = .loaded(image)

            case .noThumbnail:
                state = .noThumbnail

            case .error:
                state = .error
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else {
                return
            }

            state = .error
        }
    }

    private func fallbackView(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.title)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum ThumbnailState {
    case loading
    case loaded(CGImage)
    case noThumbnail
    case error
}
