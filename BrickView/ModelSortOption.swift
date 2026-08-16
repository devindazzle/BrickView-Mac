//
//  ModelSortOption.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Defines the available model sorting criteria and sort order.
//

import Foundation

enum ModelSortOption: Equatable {
    case filename
    case creationDate
    case modificationDate
}

enum ModelSortOrder: Equatable {
    case ascending
    case descending
}

