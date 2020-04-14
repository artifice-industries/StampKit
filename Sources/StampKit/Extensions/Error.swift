//
//  Error.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation

public enum SKResponseError: Error {
    case invalidMessageType
    case invalidArguments
    case stringDecoding
    case jsonConversion
}

extension SKResponseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidMessageType: return NSLocalizedString("Invalid message type", comment: "")
        case .invalidArguments: return NSLocalizedString("Invalid amount or type of OSC arguments", comment: "")
        case .stringDecoding: return NSLocalizedString("Unable to decode string argument", comment: "")
        case .jsonConversion: return NSLocalizedString("Unable to convert json to dictionary", comment: "")
        }
    }
}

public enum SKTimelineError: Error {
    case serverConnection
    case connectionUnauthorised
    case heartbeat
    case unknown
}

extension SKTimelineError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serverConnection: return NSLocalizedString("Couldnt connect to server", comment: "")
        case .connectionUnauthorised: return NSLocalizedString("Connection Unauthorised", comment: "")
        case .heartbeat: return NSLocalizedString("Received no heartbeat from server", comment: "")
        case .unknown: return NSLocalizedString("Unknown", comment: "")
        }
    }
}
