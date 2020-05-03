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
    
    public enum SKReceiveMessageType {
        case timelines
        case connect
        case disconnect
        case note
        case response
        case update
        case unknown
    }
    
    public var type: SKReceiveMessageType {
        get {
            if self.isTimelines {
                return .timelines
            }  else if self.isConnect {
                return .connect
            } else if self.isDisconnect {
                return .disconnect
            } else if self.isNote {
                return .note
            } else if self.isResponse {
                return .response
            } else if self.isUpdate {
                return .update
            } else {
                return .unknown
            }
        }
    }
    
    // MARK:- Replies
    // Address Pattern: /response...
    private var isResponse: Bool {
        get {
            return self.addressPattern.hasPrefix(SKAddressParts.response.rawValue)
        }
    }
    
    // MARK:- Updates
    public enum SKReceiveMessageUpdateType {
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
    
    public func updateType() -> SKReceiveMessageUpdateType {
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
    
    // Address Pattern: /timeline/{Unique ID}/note or /stamp/note and needs atleast one string argument.
    private var isNote: Bool {
        guard arguments.count >= 1, arguments[0] is String else { return false }
        return addressPattern.hasSuffix(SKAddressParts.note.rawValue)
    }
    
    // MARK:- Helper Methods
    
    // Adds the /stamp/ prefix to an address pattern.
    // Address Pattern: /stamp/...
    func applicationMessage() -> OSCMessage {
        if !self.addressPattern.hasPrefix(SKAddressParts.application.rawValue) {
            let applicationMessage = OSCMessage(messageWithAddressPattern: "\(SKAddressParts.application.rawValue)\(self.addressPattern)", arguments: self.arguments)
            applicationMessage.replySocket = self.replySocket
            return applicationMessage
        }
        return self
    }
    
    func applicationAddressPattern() -> String {
        return !self.addressPattern.hasPrefix(SKAddressParts.application.rawValue) ? "\(SKAddressParts.application.rawValue)\(self.addressPattern)" : self.addressPattern
    }
    
    // Removes the /stamp/ prefix to an address pattern.
    // Address Pattern: /...
    func message() -> OSCMessage {
        if self.addressPattern.hasPrefix(SKAddressParts.application.rawValue) {
            let startIndex = SKAddressParts.application.rawValue.index(SKAddressParts.application.rawValue.startIndex, offsetBy: SKAddressParts.application.rawValue.count)
            let message = OSCMessage(messageWithAddressPattern: String(self.addressPattern[startIndex...]), arguments: self.arguments)
            message.replySocket = self.replySocket
            return message
        }
        return self
    }
    
    public func address() -> String {
        let startIndex = self.addressPattern.index(self.addressPattern.startIndex, offsetBy: SKAddressParts.response.rawValue.count)
        return isResponse ? String(self.addressPattern[startIndex...]) : self.addressPattern
    }
    
    public func responseAddress() -> String {
        return "\(SKAddressParts.response.rawValue)\(addressPattern)"
    }

    public func addressWithoutTimeline(timelineID: String? = nil) -> String {
        let oldAddress = address()
        guard let uniqueID = timelineID else { return oldAddress }
        let timelinePrefix = "\(SKAddressParts.timeline.rawValue)/\(uniqueID)"
        if oldAddress.hasPrefix(timelinePrefix) {
            let startIndex = oldAddress.index(oldAddress.startIndex, offsetBy: timelinePrefix.count)
            return String(oldAddress[startIndex...])
        } else {
            return oldAddress
        }
    }
    
    public func response() throws -> SKPacket {
        guard self.isResponse else { throw SKResponseError.invalidMessageType }
        guard self.arguments.count == 1, let argument = self.arguments[0] as? String else { throw SKResponseError.invalidArguments }
        guard let body = argument.data(using: .utf8) else { throw SKResponseError.stringDecoding }
        let decoder = JSONDecoder()
        let packet = try decoder.decode(SKPacket.self, from: body)
        return packet
    }
    
    func uuid() -> String? {
        guard addressParts[0] == SKAddressParts.timeline.rawValue.dropFirst() else { return nil }
        return addressParts[1]
    }

}
