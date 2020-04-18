//
//  SKNoteDescription.swift
//  StampKit
//
//  Created by Sam Smallman on 18/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

// MARK:- Overview
// A description of a Note Stamp in StampKit.

import Foundation

/// A note descriptor that describes a Note Stamp.
public struct SKNoteDescription {
    
    public let code: SKResponseStatusCode
    public let note: String
    public let colour: SKNoteColour
    
    public init(note: String, colour: SKNoteColour, code: SKResponseStatusCode) {
        self.note = note
        self.colour = colour
        self.code = code
    }
    
}

extension SKNoteDescription: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case note, colour, code = "response_status_code"
    }
    
}
