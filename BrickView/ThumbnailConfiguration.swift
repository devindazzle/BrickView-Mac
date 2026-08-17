//
//  ThumbnailConfiguration.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

import CoreGraphics

struct ThumbnailSizeDefinition: Equatable {
    let thumbnailSize: CGSize
    let cardSize: CGSize
    let itemSize: CGSize
}

enum ThumbnailConfiguration {
    static let small = ThumbnailSizeDefinition(
        thumbnailSize: CGSize(
            width: 240,
            height: 160
        ),
        cardSize: CGSize(
            width: 240,
            height: 210
        ),
        itemSize: CGSize(
            width: 258,
            height: 230
        )
    )

    static let medium = ThumbnailSizeDefinition(
        thumbnailSize: CGSize(
            width: 360,
            height: 240
        ),
        cardSize: CGSize(
            width: 360,
            height: 290
        ),
        itemSize: CGSize(
            width: 378,
            height: 310
        )
    )

    static let large = ThumbnailSizeDefinition(
        thumbnailSize: CGSize(
            width: 480,
            height: 320
        ),
        cardSize: CGSize(
            width: 480,
            height: 370
        ),
        itemSize: CGSize(
            width: 498,
            height: 390
        )
    )

    static var displaySize: CGSize {
        medium.thumbnailSize
    }
}
