//
//  SKTimeline.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit
import os.log

public protocol SKTimelineDelegate {
    func timeline(error: Error)
    func timelineDidDisconnect(timeline: SKTimeline)
}

public final class SKTimeline: NSObject {
    
    public override var description: String { get { return "\(super.description) - \(self.name) - \(self.uniqueID)" } }
    public var fullName: String { get { return "\(name) (\(server.name))" }}
    public private(set) var password: (required: Bool, text: String?) = (false, nil)
    public private(set) var uniqueID: String = ""
    public private(set) var name: String = ""
    public private(set) var connected = false
    
    public var delegate: SKTimelineDelegate?
    public var reconnection: Bool = false
    
    private var heartbeats = -1 // Not running
    private var heartbeatTimer: Timer?
    private var client: SKClient
    private var server: SKServerFacade
    
    internal init(with timeline: SKTimelineDescription, andServer server: SKServerFacade) {
        self.uniqueID = timeline.uuid.uuidString
        self.client = SKClient(with: server.host, port: server.port, useTCP: true)
        self.server = server
        super.init()
        let _ = update(with: timeline)
    }
    
    deinit {
        client.delegate = nil
    }
    
    internal func update(with timeline: SKTimelineDescription) -> Bool {
        var didUpdate = false
        if timeline.name != name {
            name = timeline.name
            didUpdate = true
        }
        if timeline.hasPassword != password.required {
            password.required = timeline.hasPassword
            didUpdate = true
        }
        return didUpdate
    }
    
    // MARK:- Connection/Disconnection
    public func connect(with password: String? = nil, completionHandler: SKTimelineHandler? = nil) {
        client.delegate = self
        if !client.connect() && !client.isConnected && !connected {
            client.delegate = nil
            delegate?.timeline(error: SKTimelineError.serverConnection)
            return
        }
        os_log("Connecting: %{PUBLIC}@", log: .timeline, type: .info, name)
        client.sendMessage(with: SKAddressParts.connect.rawValue, arguments: password != nil ? [password!] : [], completionHandler: { [weak self] data in
            guard let strongSelf = self else { return }
            guard case .connect(let description) = data else { return }
            if description.status == SKConnectionStatus.authorised.rawValue {
                if strongSelf.password.required {
                    strongSelf.password.text = password
                } else {
                    strongSelf.password.text = nil
                }
                os_log("Connected: %{PUBLIC}@", log: .timeline, type: .info, strongSelf.name)
                strongSelf.finishConnecting()
            } else {
                strongSelf.client.delegate = nil
                strongSelf.client.disconnect()
                if description.status == SKConnectionStatus.unauthorised.rawValue {
                    os_log("Unauthorised Access: Incorrect Password", log: .timeline, type: .info)
                    strongSelf.delegate?.timeline(error: SKTimelineError.connectionUnauthorised)
                } else {
                    os_log("Unknown Connection Error", log: .timeline, type: .error)
                    strongSelf.delegate?.timeline(error: SKTimelineError.unknown)
                }
            }
            guard let completion = completionHandler else { return }
            completion(strongSelf)
        })
    }
    
    private func finishConnecting() {
        guard !connected else { return }
        connected = true
    }
    
    public func reconnect() {
        // Reconnect using last-known password, e.g. when the application wakes from sleep.
        os_log("Reconnecting...", log: .timeline, type: .info)
        connect(with: self.password.text)
    }
    
    public func disconnect() {
        os_log("Disconnect: %{PUBLIC}@", log: .timeline, type: .info, name)
        stopHeartbeat()
        disconnectFromTimelines()
        client.delegate = nil
        connected = false
        client.disconnect()
    }
    
    // MARK:- Heartbeat
    
    public func heartbeat(_ beat: Bool) {
        os_log("Heartbeat: %{PUBLIC}@", log: .timeline, type: .info, "\(beat)")
        beat ? startHeartbeat() : stopHeartbeat()
    }
    
    private func startHeartbeat() {
        clearHeartbeatTimeout()
        sendHeartbeat()
    }
    
    private func stopHeartbeat() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(sendHeartbeat), object: nil)
        clearHeartbeatTimeout()
        heartbeats = -1
    }
    
    private func clearHeartbeatTimeout() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeats = 0
    }
    
    @objc func sendHeartbeat() {
        client.sendMessage(with: SKAddressParts.heartbeat.rawValue, arguments: [], completionHandler: { [weak self] data in
            guard let strongSelf = self else { return }
            
            guard strongSelf.heartbeats > -1 else { return }
            strongSelf.clearHeartbeatTimeout()
            guard strongSelf.connected && strongSelf.client.isConnected else { return }
            
            strongSelf.perform(#selector(strongSelf.sendHeartbeat), with: nil, afterDelay: StampKitHeartbeatInterval)
            
        })
        
        heartbeatTimer = Timer(timeInterval: StampKitHeartbeatFailureInterval, target: self, selector: #selector(heartbeatTimeout(timer:)), userInfo: nil, repeats: false)
        RunLoop.current.add(heartbeatTimer!, forMode: .common)
    }
    
    @objc func heartbeatTimeout(timer: Timer) {
        // The connection could have disconnected whilst waiting for a response.
        guard timer.isValid, heartbeats != -1, connected else { return }
        
        // If the timer fires before we receive a response from the hearbeat and we have attempts left, try sending again.
        if heartbeats < StampKitHeartbeatMaxAttempts {
            heartbeats += 1
            sendHeartbeat()
        } else {
            os_log("No Heartbeat...", log: .timeline, type: .info)
            delegate?.timeline(error: SKTimelineError.heartbeat)
        }
    }
    
    // MARK:- Timeline Methods
    
    private func disconnectFromTimelines() {
        client.sendMessage(with: SKAddressParts.disconnect.rawValue, arguments: [])
    }
    
    public func send(message: OSCMessage) {
        client.send(message: message)
    }
    
    public func request(note: String, withColour colour: SKNoteColour, completionHandler: SKNoteHandler? = nil) {
        os_log("Sending Note: %{PUBLIC}@", log: .timeline, type: .info, note)
        client.sendMessage(with: SKAddressParts.note.rawValue, arguments: [note, colour.rawValue], completionHandler: { data in
            guard case .note(let description) = data else { return }
            guard let completion = completionHandler else { return }
            os_log("Receiving Note Reply: %{PUBLIC}@", log: .timeline, type: .info, description.note)
            completion(description)
        })
    }
    
}

extension SKTimeline: SKClientDelegate {
    
    func timelineDidDisconnect() {
        guard connected else { return }
        disconnect()
        os_log("Disconnected", log: .timeline, type: .info)
        delegate?.timelineDidDisconnect(timeline: self)
        
    }
    
    var timelineID: String { return uniqueID }
    var disconnectOnError: Bool { get { return reconnection } }
    
}
