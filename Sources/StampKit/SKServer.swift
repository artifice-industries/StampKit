//
//  SKServer.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

protocol SKServerDelegate {
    func serverDidUpdateTimelines(server: SKServer)
}

class SKServer: NSObject {
    
    var isConnected: Bool { get { return client.isConnected } }
    var timelines: Set<SKTimeline> = []
    var delegate: SKServerDelegate?
    var refreshTimer: Timer?
    var service: NetService?
    var name: String
    
    let client: SKClient
    let host: String
    let port: Int

    // Create a private client that we'll use for querying the list of timelines on the Stamp server.
    convenience init(host: String, port: UInt16) {
        let client = SKClient(with: host, port: port, useTCP: true)
        self.init(host: host, port: port, client: client)
    }
    
    init(host: String, port: Int, client: SKClient) {
        self.host = host
        self.port = port == 0 ? StampKitTxPortNumber : port
        self.name = host
        self.service = nil
        self.client = client
    }
    
    deinit {
        stop()
    }
    
    internal func stop() {
        disableAutoRefresh()
        client.disconnect()
        timelines.removeAll()
    }
    
    // MARK:- Timelines
    
    private func timeline(with uniqueID: String) -> SKTimeline? {
        return timelines.first(where: { $0.uniqueID == uniqueID })
    }
    
    internal func update(timelines: [[String: AnyObject]]) {
        var newTimelines: Set<SKTimeline> = []
        for dictionary in timelines {
            guard let uniqueID = dictionary[SKOSCKeys.uniqueID.rawValue] as? String else { continue }
            if let existingTimeline = timeline(with: uniqueID) {
                newTimelines.insert(existingTimeline)
                _ = existingTimeline.update(with: dictionary)
            } else {
                let timeline = SKTimeline(with: dictionary, andServer: self)
                newTimelines.insert(timeline)
            }
        }
        self.timelines = newTimelines
        delegate?.serverDidUpdateTimelines(server: self)
    }
    
    @objc internal func refreshTimelines() {
        guard !client.isConnected && !client.connect() else {
            os_log("Error - SKServer unable to connect to to Stamp server: %{PUBLIC}@, %{PUBLIC}@:%{PUBLIC}@", log: .server, type: .info, self.host, "\(self.port)")
            return
        }
    
        client.sendMessage(with: "/\(SKAddressParts.timelines.rawValue)", arguments: [], timeline: false, completionHandler: { [weak self] completionHandler in
            guard let strongSelf = self else { return }
            guard let timelineUpdates = completionHandler as? [[String: AnyObject]] else { return }
            
            strongSelf.update(timelines: timelineUpdates)
        })
        
    }
    
    internal func refresh(withCompletionHandler completionHandler: @escaping SKCompletionHandler) {
        
        guard !client.isConnected && !client.connect() else {
            os_log("Error - SKServer unable to connect to to Stamp server: %{PUBLIC}@, %{PUBLIC}@:%{PUBLIC}@", log: .server, type: .info, self.host, "\(self.port)")
            return
        }
        
        client.sendMessage(with: "/\(SKAddressParts.timelines.rawValue)", arguments: [], timeline: false, completionHandler: { [weak self] data in
            guard let strongSelf = self else { return }
            guard let timelineUpdates = data as? [[String: AnyObject]] else { return }
            
            strongSelf.update(timelines: timelineUpdates)
            
            completionHandler(strongSelf.timelines as AnyObject)
        })

    }
    
    internal func enableAutoRefresh(with interval: TimeInterval) {
        if refreshTimer == nil {
            refreshTimer = Timer(timeInterval: interval, target: self, selector: #selector(refreshTimelines), userInfo: nil, repeats: true)
        }
    }
    
    internal func disableAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
}
