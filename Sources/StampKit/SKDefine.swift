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
    case updates = "/updates"
    case heartbeat = "/thump"
}

// MARK:- Timeline Password
enum SKTimelinePassword: String {
    case authorised
    case unauthorised
}


