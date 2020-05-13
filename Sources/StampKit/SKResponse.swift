//
//  SKResponse.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit

public enum SKResponseKeys: String {
    case text
    case colour
}

public final class SKResponse {
    
    public static func response(for message: OSCMessage, withDictionary dictionary: [String : Any], andCode code: SKResponseStatusCode) -> OSCMessage? {
        switch message.type {
        case .note: return noteCreateResponse(for: message, withDictionary: dictionary, andCode: code)
        default: return nil
        }
    }
    
    // MARK:- Note
    private static func noteCreateResponse(for message: OSCMessage, withDictionary dictionary: [String : Any], andCode code: SKResponseStatusCode) -> OSCMessage {
        var noteColour = SKNoteColour.green
        if let colour = dictionary[SKResponseKeys.colour.rawValue] as? SKNoteColour {
            noteColour = colour
        } else if message.arguments.count >= 2, let colourArgument = message.arguments[1] as? String, let colour = SKNoteColour(rawValue: colourArgument) {
            noteColour = colour
        }
        var noteText = ""
        if let note = dictionary[SKResponseKeys.text.rawValue] as? String {
            noteText = note
        } else if let note = message.arguments[0] as? String {
            noteText = note
        }
        let string = SKPacket.jsonString(for: message.addressPattern(withApplication: true), data: .note(SKNoteDescription(text: noteText, colour: noteColour, code: code)))
        let response = OSCMessage(messageWithAddressPattern: message.responseAddress(), arguments: [string])
        response.readdress(to: response.addressPattern(withApplication: true))
        return response
    }
    
}
