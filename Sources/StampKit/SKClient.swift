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
    var timelineID: String { get }
    var disconnectOnError: Bool { get }
    func timelineDidDisconnect()
}

extension SKClientDelegate {
    var disconnectOnError: Bool { get { return false } }
}

final class SKClient {
    
    private let client = OSCClient()
    private var completionHandlers: [String : SKCompletionHandler] = [:]
    private var timelinePrefix: String {
        get {
            guard let delegate = delegate else { return ""}
            return "\(SKAddressParts.timeline.rawValue)/\(delegate.timelineID)"
        }
    }
    
    public var isConnected: Bool { get { return client.isConnected } }
    public var delegate: SKClientDelegate?
    
    init(with host: String, port: Int) {
        client.host = host
        client.port = UInt16(port)
        client.useTCP = true
        client.delegate = self
    }
    
    convenience init(with host: String, port: Int, useTCP: Bool) {
        self.init(with: host, port: port)
        client.useTCP = useTCP
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
//        client.delegate = nil
    }
    
    internal func useTCP() {
        client.useTCP = true
    }
    
    func send(message: OSCMessage, withCompletionHandler completionHandler: SKCompletionHandler? = nil) {
        if let handler = completionHandler {
            self.completionHandlers[message.addressPattern] = handler
        }
        client.send(packet: message)
    }
    
    // Optional parameters within a closure are escaping by default.
    func sendMessage(with addressPattern: String, arguments: [Any], timeline: Bool = true, completionHandler: SKCompletionHandler? = nil) {
        if let handler = completionHandler {
//            os_log("Adding completion handler for: %{PUBLIC}@", log: .client, type: .info, addressPattern)
            self.completionHandlers[addressPattern] = handler
        }
        let fullAddress = timeline && delegate != nil ? "\(timelinePrefix)\(addressPattern)" : addressPattern
        let message = OSCMessage(messageWithAddressPattern: fullAddress, arguments: arguments)
        
//        let annotation = OSCAnnotation.annotation(for: message, with: .spaces, andType: true)
        
        if message.addressPattern != "/timelines" {
            os_log("Sending: %{PUBLIC}@", log: .client, type: .info, message.addressPattern)
        }
        client.send(packet: message)
    }
    
    func process(message: OSCMessage) {
        let annotation = OSCAnnotation.annotation(for: message, with: .spaces, andType: true)
        switch message.type {
        case .response:
            if message.addressPattern != "/response/timelines" {
                os_log("Reply: %{PUBLIC}@", log: .client, type: .info, message.addressPattern)
            }
            do {
                let data = try message.response().data
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    let relativeAddress = message.addressWithoutTimeline(timelineID: strongSelf.delegate?.timelineID)
//                    os_log("Getting completion handler for: %{PUBLIC}@", log: .client, type: .info, relativeAddress)
                    guard let completionHandler = strongSelf.completionHandlers[relativeAddress] else { return }
                    strongSelf.completionHandlers.removeValue(forKey: relativeAddress)
                    completionHandler(data)
                }
            } catch {
                os_log("Error: %{PUBLIC}@", log: .client, type: .error, error.localizedDescription)
            }
        case .update:
            os_log("Update: %{PUBLIC}@", log: .client, type: .info, annotation)
            switch message.updateType() {
            case .disconnect:
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.timelineDidDisconnect()
                }
            case .timeline: break
            case .unknown: break
            }
        case .unknown:
            os_log("Unknown Message: %{PUBLIC}@", log: .client, type: .info, annotation)
        default: break
        }
    }
    
}

extension SKClient: OSCClientDelegate {
    
    func clientDidConnect(client: OSCClient) {
        os_log("Connected: %{PUBLIC}@ %{PUBLIC}@ - %{PUBLIC}@", log: .client, type: .info, client.description, client.host!, "\(client.port)")
    }
    
    func clientDidDisconnect(client: OSCClient) {
        os_log("Disconnected: %{PUBLIC}@ %{PUBLIC}@ - %{PUBLIC}@", log: .client, type: .info, client.description, client.host!, "\(client.port)")
        
        if delegate?.disconnectOnError == true {
            disconnect()
            delegate?.timelineDidDisconnect()
        }
    }
    
}

extension SKClient: OSCPacketDestination {
    
    func take(bundle: OSCBundle) {
        os_log("Received Bundle with Timetag: %{public}@", log: .client, type: .info, "\(bundle.timeTag)")
    }
    
    func take(message: OSCMessage) {
        process(message: message)
    }
    
}
