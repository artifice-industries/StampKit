//
//  SKTimeline.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation

class SKTimeline: NSObject {
    
    var name: String = ""
    var uniqueID: String = ""
    var hasPasscode: Bool = false
    
    init(with dictionary: [String: AnyObject], andServer server: SKServer) {
        
    }
    
    func update(with dictionary: [String: AnyObject]) -> Bool {
        var didUpdate = false
        if let displayName = dictionary[SKOSCDisplayNameKey] as? String, displayName != name {
            name = displayName
            didUpdate = true
        }
        if let passcode = dictionary[SKOSCHasPasscodeKey] as? Bool, hasPasscode != passcode {
            hasPasscode = passcode
            didUpdate = true
        }
        return didUpdate
    }
}
