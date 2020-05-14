//
//  SKServerFacade.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

protocol SKServerFacadeDelegate {
    func serverDidUpdateTimelines(server: SKServerFacade)
}

public final class SKServerFacade: NSObject {
    
    public override var description: String { get { return "\(super.description) - \(self.name) - \(self.host) - \(self.port)" } }
    var isConnected: Bool { get { return client.isConnected } }
    public var timelines: Set<SKTimeline> = []
    var delegate: SKServerFacadeDelegate?
    var refreshTimer: Timer?
    var service: NetService?
    public var name: String
    public let uuid = UUID()
    let client: SKClient
    let host: String
    let port: Int

    // Create a private client that we'll use for querying the list of timelines on the Stamp Server.
    public convenience init(host: String, port: Int) {
        let client = SKClient(with: host, port: port, useTCP: true)
        self.init(host: host, port: port, client: client)
    }
    
    internal init(host: String, port: Int, client: SKClient) {
        self.host = host
        self.port = port == 0 ? StampKitPortNumber : port
        self.name = host
        self.service = nil
        self.client = client
    }
    
    deinit {
        stop()
    }
    
    public func stop() {
        stopRefreshTimer()
        client.disconnect()
        timelines.removeAll()
    }
    
    // MARK:- Timelines
    
    private func timeline(with uuid: UUID) -> SKTimeline? {
        return timelines.first(where: { $0.uuid == uuid })
    }
    
    internal func update(with descriptions: [SKTimelineDescription]) {
        var newTimelines: Set<SKTimeline> = []
        for description in descriptions {
            if let existingTimeline = timeline(with: description.uuid) {
                newTimelines.insert(existingTimeline)
                _ = existingTimeline.update(with: description)
            } else {
                let timeline = SKTimeline(with: description, andServer: self)
                newTimelines.insert(timeline)
            }
        }
        self.timelines = newTimelines
        delegate?.serverDidUpdateTimelines(server: self)
    }
    
    @objc public func refreshTimelines() {
        
        if !client.connect() && !client.isConnected {
            os_log("Error: Unable to connect to Stamp Server: %{PUBLIC}@:%{PUBLIC}@", log: .serverFacade, type: .error, host, "\(port)")
            return
        }
    
        client.sendMessage(with: SKAddressParts.timelines.rawValue, arguments: [], timeline: false, completionHandler: { [weak self] data in
            guard let strongSelf = self else { return }
            guard case .timelines(let descriptions) = data else { return }
            
            strongSelf.update(with: descriptions)
        })
        
    }
    
    public func refreshTimelines(withCompletionHandler completionHandler: SKTimelinesHandler? = nil) {
        
        if !client.connect() && !client.isConnected {
            os_log("Error: Unable to connect to Stamp Server: %{PUBLIC}@:%{PUBLIC}@", log: .serverFacade, type: .error, host, "\(port)")
            return
        }
    
        client.sendMessage(with: SKAddressParts.timelines.rawValue, arguments: [], timeline: false, completionHandler: { [weak self] data in
            guard let strongSelf = self else { return }
            guard case .timelines(let descriptions) = data else { return }
            
            strongSelf.update(with: descriptions)
            guard let completion = completionHandler else { return }
            completion(descriptions)
        })
        
    }
    
    internal func refresh(every timeInterval: TimeInterval) {
        if refreshTimer == nil {
            refreshTimer = Timer(timeInterval: timeInterval, target: self, selector: #selector(refreshTimelines), userInfo: nil, repeats: true)
        }
    }
    
    internal func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
}
