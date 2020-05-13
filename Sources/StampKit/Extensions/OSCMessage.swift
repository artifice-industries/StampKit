//
//  OSCMessage.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit

extension OSCMessage {
    
    internal enum SKReceiveMessageType {
        case timelines
        case connect
        case disconnect
        case notes
        case note
        case response
        case update
        case unknown
    }
    
    internal var type: SKReceiveMessageType {
        get {
            if self.isTimelines {
                return .timelines
            }  else if self.isConnect {
                return .connect
            } else if self.isDisconnect {
                return .disconnect
            } else if self.isResponse {
                return .response
            } else if self.isUpdate {
                return .update
            } else if self.isNotes {
                return .notes
            } else if self.isNote {
                return .note
            } else {
                return .unknown
            }
        }
    }
    
    internal var isForStamp: Bool { get { self.addressPattern.hasPrefix(SKAddressParts.application.rawValue) } }
    
    // MARK:- Replies
    // Address Pattern: /response...
    private var isResponse: Bool {
        get {
            return self.addressPattern.hasPrefix(SKAddressParts.response.rawValue)
        }
    }
    
    // MARK:- Updates
    internal enum SKReceiveMessageUpdateType {
        case timeline
        case disconnect
        case unknown
    }
    
    // Address Pattern: /update/...
    private var isUpdate: Bool {
        get {
            return self.addressPattern.hasPrefix(SKAddressParts.update.rawValue)
        }
    }
    
    internal func updateType() -> SKReceiveMessageUpdateType {
        guard isUpdate else { return .unknown }
        if addressParts.count == 3 && addressParts[1] == SKAddressParts.timeline.rawValue.dropFirst() {
            return .timeline
        }
        if addressParts.count == 4 && addressParts[3] == SKAddressParts.disconnect.rawValue.dropFirst() {
            return .disconnect
        }
        return .unknown
    }
    
    // MARK:- Timelines
    // Address Pattern: /timelines
    private var isTimelines: Bool {
        return self.addressPattern == SKAddressParts.timelines.rawValue
    }
    
    // Address Pattern: /timeline/{Unique ID}/connect
    private var isConnect: Bool {
        return addressParts.count == 3 && addressParts[2] == SKAddressParts.connect.rawValue.dropFirst()
    }
    
    // Address Pattern: /timeline/{Unique ID}/disconnect
    private var isDisconnect: Bool {
        return addressParts.count == 3 && addressParts[2] == SKAddressParts.disconnect.rawValue.dropFirst()
    }
    
    // Address Pattern: /timeline/{Unique ID}/notes or /stamp/notes.
    private var isNotes: Bool {
        return addressPattern.hasSuffix(SKAddressParts.notes.rawValue) && arguments.count == 0
    }
    
    // Address Pattern: /timeline/{Unique ID}/note or /stamp/note and needs atleast one string argument.
    private var isNote: Bool {
        guard arguments.count >= 1, arguments[0] is String else { return false }
        return addressPattern.hasSuffix(SKAddressParts.note.rawValue)
    }
    
    // MARK:- Helper Methods
    
    internal func addressPattern(withApplication application: Bool) -> String {
        if application {
            return !self.addressPattern.hasPrefix(SKAddressParts.application.rawValue) ? "\(SKAddressParts.application.rawValue)\(self.addressPattern)" : self.addressPattern
        } else {
            let startIndex = SKAddressParts.application.rawValue.index(SKAddressParts.application.rawValue.startIndex, offsetBy: SKAddressParts.application.rawValue.count)
            return String(self.addressPattern[startIndex...])
        }
    }
    
    internal func responseAddress() -> String {
        return "\(SKAddressParts.response.rawValue)\(addressPattern)"
    }
    
    private func addressWithoutResponse() -> String {
        let startIndex = self.addressPattern.index(self.addressPattern.startIndex, offsetBy: SKAddressParts.response.rawValue.count)
        return isResponse ? String(self.addressPattern[startIndex...]) : self.addressPattern
    }

    internal func addressWithoutTimeline(timelineID: String? = nil) -> String {
        let oldAddress = addressWithoutResponse()
        guard let uniqueID = timelineID else { return oldAddress }
        let timelinePrefix = "\(SKAddressParts.timeline.rawValue)/\(uniqueID)"
        if oldAddress.hasPrefix(timelinePrefix) {
            let startIndex = oldAddress.index(oldAddress.startIndex, offsetBy: timelinePrefix.count)
            return String(oldAddress[startIndex...])
        } else {
            return oldAddress
        }
    }
    
    internal func response() throws -> SKPacket {
        guard self.isResponse else { throw SKResponseError.invalidMessageType }
        guard self.arguments.count == 1, let argument = self.arguments[0] as? String else { throw SKResponseError.invalidArguments }
        guard let body = argument.data(using: .utf8) else { throw SKResponseError.stringDecoding }
        let decoder = JSONDecoder()
        let packet = try decoder.decode(SKPacket.self, from: body)
        return packet
    }
    
    internal func uuid() -> String? {
        guard addressParts[0] == SKAddressParts.timeline.rawValue.dropFirst(), addressParts.indices.contains(1) else { return nil }
        return addressParts[1]
    }

}
