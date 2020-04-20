//
//  SKServer.swift
//  StampKit
//
//  Created by Sam Smallman on 01/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit
import os.log

public protocol SKServerDelegate {
    func server(_: SKServer, didUpdateTimelines: [SKTimelineDescription])
    func server(_: SKServer, didUpdateConnectedClients clients: [SKClientFacade], toTimeline timeline: SKTimelineDescription)
    func server(_: SKServer, didReceiveMessage message: OSCMessage, forTimelines timelines: [SKTimelineDescription])
    func statusCode(for client: SKClientFacade, sendingMessage message: OSCMessage, toServer server: SKServer, forTimelines timelines: [SKTimelineDescription]) -> SKResponseStatusCode
}

public enum SKServerStatus: String {
    case online
}

final public class SKServer: NSObject {
    
    public private(set) var timelines: [SKTimelineDescription] = [] { didSet { delegate?.server(self, didUpdateTimelines:timelines) } }
    private let publisher: SKPublisher
    private let server: OSCServer
    public private(set) var status: SKServerStatus = .online
    public private(set) var connections: [String : [SKClientFacade]]
    
    public var delegate: SKServerDelegate?
    
    public override init() {
        publisher = SKPublisher()
        server = OSCServer()
        server.port = UInt16(StampKitPortNumber)
        connections = [:]
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        publisher.publish()
        server.delegate = self
        do {
            try server.startListening()
        } catch let error as NSError {
            os_log("Error: %{public}@", log: .server, type: .error, error.localizedDescription)
        }
    }
    
    public func stop() {
        publisher.stop()        
    }
    
    public func add(timeline: SKTimelineDescription) {
        if timelines.contains(timeline), let index = timelines.firstIndex(of: timeline) {
            timelines[index] = timeline
        } else {
            timelines.append(timeline)
        }
    }
    
    public func remove(timeline: SKTimelineDescription) {
        if timelines.contains(timeline), let index = timelines.firstIndex(of: timeline) {
            timelines.remove(at: index)
        }
    }
    
    public func change(timeline:SKTimelineDescription, name: String) {
        if timelines.contains(timeline), let index = timelines.firstIndex(of: timeline), timeline.name != name {
            let newTimeline = SKTimelineDescription(name: name, uuid: timeline.uuid, andPassword: timeline.password)
            timelines[index] = newTimeline
        }
    }
    
    public func change(timeline: SKTimelineDescription, password: String) {
        if timelines.contains(timeline), let index = timelines.firstIndex(of: timeline), timeline.password != password {
            let newTimeline = SKTimelineDescription(name: timeline.name, uuid: timeline.uuid, andPassword: password)
            timelines[index] = newTimeline
        }
    }
    
    public func timeline(withUUID uuid: String) -> SKTimelineDescription? {
        return timelines.first(where: { $0.uuid.uuidString == uuid })
    }
    
    func process(message: OSCMessage) {
        switch message.type {
        case .timelines:    timelines(with: message)
        case .connect:      connect(with: message)
        case .disconnect:   disconnect(with: message)
        case .note:         note(with: message)
        case .unknown:
            switch timelinesAuthorised(for: message) {
            case (true, let descriptions) where !descriptions.isEmpty :
                delegate?.server(self, didReceiveMessage: message, forTimelines: descriptions)
            default: break
            }
        default: break
        }
    }
    
    private func timelinesAuthorised(for message: OSCMessage) -> (authorisation: Bool, timelines: [SKTimelineDescription]) {
        // The message is referencing a timeline
        if let uuid = message.uuid(), let clients = connections[uuid], let socket = message.replySocket {
            // 1. Validate authorisation
            guard clients.contains(where: { $0.hasSocket(socket: socket) }), let timelineDescription = timelines.first(where: { $0.uuid.uuidString == uuid }) else { return (false, []) }
                return (true, [timelineDescription])
        } else {
            // First get all the unsecured timelines.
            var securedTimelines = self.timelines.filter( { $0.hasPassword == false })
            if let socket = message.replySocket {
                let client = SKClientFacade(socket: socket)
                // Add the authorised connections for this client to the timelines array.
                let connnectedConnections = connections.filter( { $0.value.contains(where: { $0 == client} )})
                var connectedTimelines = self.timelines.filter( { timeline in connnectedConnections.keys.contains(where: { timeline.uuid.uuidString == $0 } )})
                // Remove repeated timelines.
                connectedTimelines = connectedTimelines.filter( { !securedTimelines.contains($0)})
                securedTimelines.append(contentsOf: connectedTimelines)
            }
            return (true, securedTimelines)
        }
    }
    
    private func jsonString(addressPattern: String, data: SKData) -> String {
        do {
            let packet = SKPacket(status: status.rawValue, addressPattern: addressPattern, version: "1.0.0", data: data)
            let encoder = JSONEncoder()
            let data = try encoder.encode(packet)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    private func timelines(with message: OSCMessage) {
        guard let socket = message.replySocket else { return }
        let string = jsonString(addressPattern: message.addressPattern, data: .timelines(timelines))
        let message = OSCMessage(messageWithAddressPattern: "\(SKAddressParts.response.rawValue)\(SKAddressParts.timelines.rawValue)", arguments: [string])
        socket.sendTCP(packet: message, withStreamFraming: .SLIP)
    }
    
    private func connect(with message: OSCMessage) {
        guard let socket = message.replySocket, let uuid = message.uuid(), let timeline = timeline(withUUID: uuid) else { return }
        
        // 1. Authorise
        if timeline.hasPassword {
            guard message.arguments.count == 1, let password = message.arguments[0] as? String, password == timeline.password else {
                let string = jsonString(addressPattern: message.addressPattern, data: .connect(SKStatusDescription(status: SKTimelinePassword.unauthorised.rawValue, uuid: timeline.uuid)))
                let reply = OSCMessage(messageWithAddressPattern: "\(SKAddressParts.response.rawValue)\(SKAddressParts.timeline.rawValue)/\(uuid)\(SKAddressParts.connect.rawValue)", arguments: [string])
                socket.sendTCP(packet: reply, withStreamFraming: .SLIP)
                return
            }
        }
        
        // 2. Update Connections
        let client = SKClientFacade(socket: socket)
        if var clients = connections[uuid] {
            if clients.contains(where: { $0 == client }), let index = clients.firstIndex(of: client) {
                clients[index] = client
            } else {
                clients.append(client)
            }
            connections[uuid] = clients
        } else {
            connections[uuid] = [client]
        }
        tidyConnections()
        
        // 3. Return Authorisation Message
        let string = jsonString(addressPattern: message.addressPattern, data: .connect(SKStatusDescription(status: SKTimelinePassword.authorised.rawValue, uuid: timeline.uuid)))
        let reply = OSCMessage(messageWithAddressPattern: "\(SKAddressParts.response.rawValue)\(SKAddressParts.timeline.rawValue)/\(uuid)\(SKAddressParts.connect.rawValue)", arguments: [string])
        socket.sendTCP(packet: reply, withStreamFraming: .SLIP)
        delegate?.server(self, didUpdateConnectedClients: connections[uuid] ?? [], toTimeline: timeline)
    }
    
    private func disconnect(with message: OSCMessage) {
        guard let socket = message.replySocket, let uuid = message.uuid(), let timeline = timeline(withUUID: uuid) else { return }
        let client = SKClientFacade(socket: socket)
        if var clients = connections[uuid] {
            clients.removeAll(where: { $0 == client })
            connections[uuid] = clients
        }
        tidyConnections()
        delegate?.server(self, didUpdateConnectedClients: connections[uuid] ?? [], toTimeline: timeline)
    }
    
    private func note(with message: OSCMessage) {
        guard let delegate = delegate, let socket = message.replySocket else { return }
        let client = SKClientFacade(socket: socket)
        switch timelinesAuthorised(for: message) {
        case (true, let descriptions):
            let code = delegate.statusCode(for: client, sendingMessage: message, toServer: self, forTimelines: descriptions)
            var colour = SKNoteColour.green
            if message.arguments.count >= 2, let colourArgument = message.arguments[1] as? String, let noteColour = SKNoteColour(rawValue: colourArgument) {
                colour = noteColour
            }
            // We should definetly have a note argument here as it shouldn't have been passed to this method if it didn't!
            guard let note = message.arguments[0] as? String else { return }
            let string = jsonString(addressPattern: message.addressPattern, data: .note(SKNoteDescription(note: note, colour: colour, code: code)))
            let reply = OSCMessage(messageWithAddressPattern: message.replyAddress(), arguments: [string])
            socket.sendTCP(packet: reply, withStreamFraming: .SLIP)
        default: break
        }

    }
    
    private func tidyConnections() {
        connections.forEach( { connections[$0.key] = $0.value.filter( { $0.isConnected == true }) })
        connections = connections.filter( { !$0.value.isEmpty})
    }
    
}

// MARK: - OSC Packet Destination Delegates
extension SKServer: OSCPacketDestination {
    
    public func take(bundle: OSCBundle) {
        os_log("Received Bundle with Timetag: %{public}@", log: .server, type: .info, "\(bundle.timeTag)")
    }
    
    public func take(message: OSCMessage) {
        process(message: message)
    }
    
}

