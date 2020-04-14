//
//  SKPublisher.swift
//  StampKit
//
//  Created by Sam Smallman on 01/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

final internal class SKPublisher: NSObject, NetServiceDelegate {
    
    private let service: NetService
    
    internal override init() {
        self.service = NetService(domain: StampKitBonjourServiceDomain, type: StampKitBonjourTCPServiceType, name: "", port: Int32(StampKitPortNumber))
    }
    
    deinit {
        stop()
    }
    
    internal func publish() {
        os_log("Advertising Service...", log: .publisher, type: .info)
        service.delegate = self
        service.publish()
    }
    
    internal func stop() {
        os_log("Stopping Advertisement...", log: .publisher, type: .info)
        service.stop()
        service.delegate = nil
    }
    
    internal func netServiceDidPublish(_ sender: NetService) {
        if sender == service {
            os_log("Published Service: %{public}@", log: .publisher, type: .info, "\(service)")
        }
    }
    
    func netServiceDidStop(_ sender: NetService) {
        os_log("Advertisement Stopped %{public}@", log: .publisher, type: .info, "\(service)")
    }
    
}
