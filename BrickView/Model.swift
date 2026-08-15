//
//  Model.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Data model representing a BrickView model file.
//
//  The model contains the information required to identify and
//  describe a BrickLink Studio .io file. It does not load files,
//  parse model contents, generate thumbnails, or perform file
//  system operations.
//

import Foundation

struct Model: Identifiable {
    let id: URL
    let filename: String
    let partCount: Int?
    
    init(url: URL, partCount: Int? = nil) {
        self.id = url
        self.filename = url.lastPathComponent
        self.partCount = partCount
    }
}
