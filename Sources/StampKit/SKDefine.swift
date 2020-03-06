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
let StampKitBonjourUDPServiceType: String = "_stamp._udp."
let StampKitBonjourServiceDomain: String = "local."
let StampKitRxPortNumber: Int = 24601
let StampKitTxPortNumber: Int = 24602

// Blocks
typealias SKCompletionHandler = (AnyObject) -> Void

// OSC key constants
let SKOSCUIDKey = "uniqueID"
let SKOSCDisplayNameKey = "displayName"
let SKOSCHasPasscodeKey = "hasPasscode"
