//
//  SKClient.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit
import os.log

protocol SKClientDelegate {
    var  timelineID: String { get }
}

class SKClient {
    
    private let client = OSCClient()
    private var callbacks: [String : SKCompletionHandler] = [:]
    private var timelinePrefix: String { get { return "/\(SKAddressParts.timeline.rawValue)/" + (delegate?.timelineID ?? "") } }
    
    public var isConnected: Bool { get { return client.isConnected } }
    public var delegate: SKClientDelegate?
    
    init(with host: String, port: Int) {
        client.host = host
        client.port = UInt16(port)
        client.useTCP = true
        client.delegate = self
    }
    
    func connect() -> Bool {
        do {
            try client.connect()
            return true
        } catch {
            return false
        }
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    internal func useTCP() {
        client.useTCP = true
    }
    
    func send(message: OSCMessage, withCompletionHandler completionHandler: SKCompletionHandler? = nil) {
        if let callback = completionHandler {
            self.callbacks[message.addressPattern] = callback
        }
        client.send(packet: message)
    }
    
    // Optional parameters within a closure are escaping by default.
    func sendMessage(with addressPattern: String, arguments: [Any], timeline: Bool = true, completionHandler: SKCompletionHandler?) {

    }
    
    func process(message: OSCMessage) {
        let annotation = OSCAnnotation.annotation(for: message, with: .spaces, andType: true)
        os_log("Input: %{PUBLIC}@", log: .client, type: .info, annotation)
    }
    
}

extension SKClient: OSCClientDelegate {
    
    func clientDidConnect(client: OSCClient) {
        print("Client Did Connect")
    }
    
    func clientDidDisconnect(client: OSCClient) {
        print("Client Did Disconnect")
    }
    
}

extension SKClient: OSCPacketDestination {
    
    func take(message: OSCMessage) {
        // Called on the client.socketDelegateQueue thread
        process(message: message)
    }
    
    func take(bundle: OSCBundle) {
        print("Take Bundle: \(bundle.timeTag)")
    }
      
}
