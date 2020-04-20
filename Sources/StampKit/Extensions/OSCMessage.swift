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
        case response
        case timelines
        case connect
        case disconnect
        case note
        case update
        case unknown
    }
    
    public var type: SKReceiveMessageType {
        get {
            if self.isResponse {
                return .response
            } else if self.isTimelines {
                return .timelines
            } else if self.isConnect {
                return .connect
            } else if self.isDisconnect {
                return .disconnect
            } else if self.isNote {
                return .note
            } else if self.isUpdate {
                return .update
            } else {
                return .unknown
            }
        }
    }
    
    // MARK:- Replies
    // Address Pattern: /stamp/response/...
    private var isResponse: Bool {
        get {
            return self.addressPattern.hasPrefix("\(SKAddressParts.application.rawValue)\(SKAddressParts.response.rawValue)")
        }
    }
    
    // MARK:- Updates
    public enum SKReceiveMessageUpdateType {
        case timeline
        case disconnect
        case unknown
    }
    
    // Address Pattern: /stamp/update/...
    private var isUpdate: Bool {
        get {
            return self.addressPattern.hasPrefix("\(SKAddressParts.application.rawValue)\(SKAddressParts.update.rawValue)")
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
    // /stamp/timelines
    private var isTimelines: Bool {
        return self.addressPattern == "\(SKAddressParts.application.rawValue)\(SKAddressParts.timelines.rawValue)"
    }
    
    // /stamp/timeline/{Unique ID}/connect
    private var isConnect: Bool {
        return addressParts.count == 3 && addressParts[2] == SKAddressParts.connect.rawValue.dropFirst()
    }
    
    // /stamp/timeline/{Unique ID}/disconnect
    private var isDisconnect: Bool {
        return addressParts.count == 3 && addressParts[2] == SKAddressParts.disconnect.rawValue.dropFirst()
    }
    
    // /stamp/timeline/{Unique ID}/note or /stamp/note and needs atleast one string argument.
    private var isNote: Bool {
        guard arguments.count >= 1, arguments[0] is String else { return false }
        return addressPattern.hasSuffix(SKAddressParts.note.rawValue)
    }
    
    // MARK:- Helper Methods
    
    public func address() -> String {
        let startIndex = self.addressPattern.index(self.addressPattern.startIndex, offsetBy: "\(SKAddressParts.application.rawValue)\(SKAddressParts.response.rawValue)".count)
        return isResponse ? String(self.addressPattern[startIndex...]) : self.addressPattern
    }
    
    public func replyAddress() -> String {
        return "\(SKAddressParts.application.rawValue)\(SKAddressParts.response.rawValue)\(addressPattern)"
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
