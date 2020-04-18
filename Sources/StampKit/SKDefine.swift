//
//  SKDefine.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation

// MARK: Bonjour (mDNS) Constants
let StampKitBonjourTCPServiceType: String = "_stamp._tcp."
let StampKitBonjourServiceDomain: String = "local."
let StampKitPortNumber: Int = 24601

// MARK:- Heartbeat
let StampKitHeartbeatMaxAttempts: Int = 5
let StampKitHeartbeatInterval: TimeInterval = 5
let StampKitHeartbeatFailureInterval: TimeInterval = 1

// MARK:- SKTimelineDescription
let StampKitPasswordRequired: String = "SKPASSWORDREQUIRED"

// MARK:- SKStatusDescription
enum SKConnectionStatus: String {
    case authorised
    case unauthorised
}

// Blocks
public typealias SKTimelineHandler = (SKTimeline) -> Void
public typealias SKNoteHandler = (SKNoteDescription) -> Void
public typealias SKCompletionHandler = (SKData) -> Void

// MARK:- Address Pattern Parts
enum SKAddressParts: String {
    case application = ""
    case reply = "/reply"
    case update = "/update"
    case timelines = "/timelines"
    case timeline = "/timeline"
    case connect = "/connect"
    case disconnect = "/disconnect"
    case note = "/note"
    case updates = "/updates"
    case heartbeat = "/thump"
}

// MARK:- Timeline Password
enum SKTimelinePassword: String {
    case authorised
    case unauthorised
}

// MARK:- Note Colour
public enum SKNoteColour: String, Codable {
    case green
    case red
    case yellow
    case purple
}

public enum SKResponseStatusCode: Int, Error, Codable {
    enum ResponseType: String, Codable {
        case success // The action requested by the client was received, understood, accepted, and processed successfully.
        case clientError // The client errored.
        case serverError // The server failed to fulfill an apparently valid request.
        case undefined // The status code cannot be resolved.
    }
    
    // MARK: Success - 2xx
    case ok = 200 // Successful Request
    case created = 201  // Request has been fulfilled, resulting in the creation of a new resource.
    case accepted = 202 // Request has been accepted for processing, but the processing has not been completed.

    // MARK: Client Error - 4xx
    case badRequest = 400 // The server cannot or will not process the request due to an apparent client error.
    case unauthorized = 401 // Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided.
    case paymentRequired = 402 // The content available on the server requires payment.
    case forbidden = 403 // The request was a valid request, but the server is refusing to respond to it.
    case notFound = 404 // The requested resource could not be found but may be available in the future.
    case methodNotAllowed = 405 // A request method is not supported for the requested resource. e.g. a GET request on a form which requires data to be presented via POST
    case conflict = 409 // The request could not be processed because of conflict in the request, such as an edit conflict between multiple simultaneous updates.
    case gone = 410 // the resource requested is no longer available and will not be available again.
    
    // MARK: Server Error - 5xx
    case internalServerError = 500 // A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.
    case notImplemented = 501 // The server either does not recognize the request method, or it lacks the ability to fulfill the request.
    case serviceUnavailable = 503 // The server is currently unavailable (because it is overloaded or down for maintenance). Generally, this is a temporary state
    case networkAuthenticationRequired = 511 // The client needs to authenticate to gain network access.
    
    // The class (or group) which the status code belongs to.
    var responseType: ResponseType {
        switch self.rawValue {
        case 200..<300: return .success
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default: return .undefined
        }
    }
}


