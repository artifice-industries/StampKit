//
//  SKTimeline.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit

class SKTimeline: NSObject {
    
    var name: String = ""
    var uniqueID: String = ""
    var connected = false
    var heartbeatAttempts = -1 // Not running
    
    var client: OSCClient
    var server: OSCServer
    
    var hasPasscode: Bool = false
    
    var attemptToReconnect: Bool = false
    
    var clientShouldDisconnectOnError { get { } }
    
    init(with dictionary: [String: AnyObject], andServer server: SKServer) {
        
    }
    
    func update(with dictionary: [String: AnyObject]) -> Bool {
        var didUpdate = false
        if let displayName = dictionary[SKOSCKeys.displayName.rawValue] as? String, displayName != name {
            name = displayName
            didUpdate = true
        }
        if let passcode = dictionary[SKOSCKeys.hasPasscodeKey.rawValue] as? Bool, hasPasscode != passcode {
            hasPasscode = passcode
            didUpdate = true
        }
        return didUpdate
    }
}
