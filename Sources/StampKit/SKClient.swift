//
//  SKClient.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation

class SKClient {
    
    var isConnected: Bool {
        get {
            return true
        }
    }
    
    init(with host: String, port: Int) {
        
    }
    
    func connect() -> Bool {
        return true
    }
    
    func disconnect() {
        
    }
    
    internal func useTCP() {
        
    }
    
    // Optional parameters within a closure are escaping by default.
    func sendMessage(with addressPattern: String, arguments: [Any], timeline: Bool = true, completionHandler: SKCompletionHandler?) {
        
    }
    
    
}
