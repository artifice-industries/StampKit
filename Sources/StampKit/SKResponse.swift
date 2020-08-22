//
//  SKResponse.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit

public enum SKResponseKey: String {
    case text
    case colour
    case notes
}

public final class SKResponse {
    
    public static func response(for message: OSCMessage, withDictionary dictionary: [SKResponseKey : Any]? = nil, andCode code: SKResponseStatusCode) -> OSCMessage? {
        switch message.type {
        case .notes: return notesResponse(for: message, withDictionary: dictionary)
        case .note: return noteCreateResponse(for: message, withDictionary: dictionary, andCode: code)
        default: return nil
        }
    }
    
    // MARK:- Note
    
    private static func notesResponse(for message: OSCMessage, withDictionary dictionary: [SKResponseKey : Any]? = nil) -> OSCMessage {
        var descriptions: [SKNoteDescription] = []
        if let dict = dictionary, let noteDescriptions = dict[SKResponseKey.notes] as? [SKNoteDescription] {
            descriptions = noteDescriptions
        }
        let string = SKPacket.jsonString(for: message.addressPattern(withApplication: true), data: .notes(descriptions))
        let response = OSCMessage(with: message.responseAddress(), arguments: [string])
        response.readdress(to: response.addressPattern(withApplication: true))
        return response
    }
    
    private static func noteCreateResponse(for message: OSCMessage, withDictionary dictionary: [SKResponseKey : Any]? = nil, andCode code: SKResponseStatusCode) -> OSCMessage {
        var noteColour = SKNoteColour.green
        if let dict = dictionary, let colour = dict[SKResponseKey.colour] as? SKNoteColour {
            noteColour = colour
        } else if message.arguments.count >= 2, let colourArgument = message.arguments[1] as? String, let colour = SKNoteColour(rawValue: colourArgument) {
            noteColour = colour
        }
        var noteText = ""
        if let dict = dictionary, let note = dict[SKResponseKey.text] as? String {
            noteText = note
        } else if let note = message.arguments[0] as? String {
            noteText = note
        }
        let string = SKPacket.jsonString(for: message.addressPattern(withApplication: true), data: .note(SKNoteDescription(text: noteText, colour: noteColour, code: code)))
        let response = OSCMessage(with: message.responseAddress(), arguments: [string])
        response.readdress(to: response.addressPattern(withApplication: true))
        return response
    }
    
}
