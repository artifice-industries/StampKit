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
    public let text: String
    public let colour: SKNoteColour
    public let email: String?
    public let name: String?
    
    public init(text: String, colour: SKNoteColour, code: SKResponseStatusCode, email: String? = nil, name: String? = nil) {
        self.text = text
        self.colour = colour
        self.code = code
        self.email = email
        self.name = name
    }
    
}

extension SKNoteDescription: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case text, colour, code = "response_status_code", email, name
    }
    
}
