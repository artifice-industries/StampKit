//
//  SKBrowser.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

public protocol SKBrowserDelegate {
    func browser(_: SKBrowser, didUpdateTimelinesForServer server: SKServerFacade)
    func browser(_: SKBrowser, didUpdateServers servers: Set<SKServerFacade>)
}

public final class SKBrowser: NSObject {
    
    private var netServiceDomainsBrowser: NetServiceBrowser?
    private var netServiceTCPBrowser: NetServiceBrowser?
    private var services: Set<NetService> = []
    public var delegate: SKBrowserDelegate?
    public var servers: Set<SKServerFacade> = []
    private var running: Bool = false
    private var refreshTimer: Timer?
    
    public override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        if running {
            os_log("Starting (already running)", log: .browser, type: .info)
        } else {
            os_log("Starting", log: .browser, type: .info)
        }
        
        if !running {
            netServiceDomainsBrowser = NetServiceBrowser()
            netServiceDomainsBrowser?.delegate = self
            netServiceDomainsBrowser?.searchForBrowsableDomains()
        }
    }
    
    public func stop() {
        stopRefreshTimer()
        netServiceDomainsBrowser?.stop()
        netServiceTCPBrowser?.stop()
        
        for server in servers {
            server.stop()
            server.delegate = nil
            server.service = nil
        }
        
        servers.removeAll()
    }
    
    @objc func refreshTimelines(timer: Timer) {
        guard let rTimer = refreshTimer, timer == rTimer, rTimer.isValid else { return }
        servers.forEach( { $0.refreshTimelines() })
    }
    
    public func refresh(every timeInterval: TimeInterval) {
        if refreshTimer == nil {
            refreshTimer = Timer(timeInterval: timeInterval, target: self, selector: #selector(refreshTimelines(timer:)), userInfo: nil, repeats: true)
            refreshTimer!.tolerance = timeInterval * 0.1
            RunLoop.current.add(refreshTimer!, forMode: .common)
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func setNeedsNotifyDelegateBrowserDidUpdateServers() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(notifyDelegateBrowserDidUpdateServers), object: nil)
        perform(#selector(notifyDelegateBrowserDidUpdateServers), with: nil, afterDelay: 0.5)
    }
    
    @objc func notifyDelegateBrowserDidUpdateServers() {
        delegate?.browser(self, didUpdateServers: servers)
    }
    
    func setNeedsBeginResolvingNetServices() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginResolvingNetServices), object: nil)
        perform(#selector(beginResolvingNetServices), with: nil, afterDelay: 0.5)
    }
    
    @objc func beginResolvingNetServices() {
        // Resolving a service could resolve immediately, changing the services array. As such make a copy of the services to iterate over.
        let netServices = services
        
        for service in netServices where service.addresses != nil {
            service.resolve(withTimeout: 5.0)
        }
    }
    
    func server(for service: NetService) -> SKServerFacade? {
        return servers.first(where: { $0.service == service })
    }
    
    func server(for hostName: String) -> SKServerFacade? {
        return servers.first(where: { $0.service?.hostName == hostName })
    }
    
}

extension SKBrowser: NetServiceBrowserDelegate {
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        if browser == netServiceDomainsBrowser {
            os_log("Will Search: Domains", log: .browser, type: .info)
        } else if browser == netServiceTCPBrowser {
            os_log("Will Search TCP Service: %{PUBLIC}@", log: .browser, type: .info, StampKitBonjourTCPServiceType)
        } else {
            os_log("Will Search: %{PUBLIC}@", log: .browser, type: .info, browser.description)
        }
        
        running = browser == netServiceDomainsBrowser
        delegate?.browser(self, didUpdateServers: servers)
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        if browser == netServiceDomainsBrowser {
            os_log("Stopping Bonjour - browsable domains search", log: .browser, type: .info)
        } else if browser == netServiceTCPBrowser {
            os_log("Stopping Bonjour (TCP) - %{PUBLIC}@", log: .browser, type: .info, StampKitBonjourServiceDomain)
        } else {
            os_log("Stopped Search: %{PUBLIC}@", log: .browser, type: .info, browser.description)
        }
        
        if browser == netServiceDomainsBrowser {
            running = false
            netServiceDomainsBrowser?.delegate = nil
            netServiceDomainsBrowser = nil
        } else if browser == netServiceTCPBrowser {
            netServiceTCPBrowser?.delegate = nil
            netServiceTCPBrowser = nil
        }
        
        delegate?.browser(self, didUpdateServers: servers)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        os_log("Didn't Search: %{PUBLIC}@", log: .browser, type: .info, browser.description)
        for error in errorDict {
            os_log("Error: %{PUBLIC}@", log: .browser, type: .info, error.value)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        os_log("Found Domain: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, domainString, "\(moreComing)")
        guard netServiceTCPBrowser == nil, domainString == StampKitBonjourServiceDomain else { return }
        netServiceTCPBrowser = NetServiceBrowser()
        netServiceTCPBrowser?.delegate = self
        netServiceTCPBrowser?.searchForServices(ofType: StampKitBonjourTCPServiceType, inDomain: StampKitBonjourServiceDomain)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        os_log("Found Service: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, service.description, "\(moreComing)")
        service.delegate = self
        services.insert(service)
        
        // Multiple calls cancel previous requests to ensure resolving only begins once (i.e if moreComming == true)
        setNeedsBeginResolvingNetServices()
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        os_log("Removed Service: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, service.description, "\(moreComing)")
        
        guard let server = server(for: service) else { return }
        server.stop()
        server.delegate = nil
        server.service = nil
        servers.remove(server)
        
        // multiple calls cancel previous requests to ensure delegate is only notified once (i.e if moreComming == true)
        setNeedsNotifyDelegateBrowserDidUpdateServers()
    }
    
}

extension SKBrowser: NetServiceDelegate {
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        os_log("Resolved Address: %{PUBLIC}@", log: .browser, type: .info, sender.description)
        guard sender.port > 0 else { return }
        
        var hostName = sender.hostName
        
        if hostName == nil || hostName?.isEmpty == true {
            guard let addresses = sender.addresses, let ipAddress = resolveIPv4(addresses: addresses) else { return }
            hostName = ipAddress
        }
        
        guard let name = hostName else { return }
        
        let server = SKServerFacade(host: name, port: sender.port)
        server.name = sender.name
        server.delegate = self
        server.service = sender
        
        // Once resolved, we can remove the net service from our locals records. The SKServer will still hold on to it.
        sender.delegate = nil
        services.remove(sender)
        
        os_log("Inserting Server: %{PUBLIC}@", log: .browser, type: .info, server.description)
        
        servers.insert(server)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.browser(strongSelf, didUpdateServers: strongSelf.servers)
        }
        
        server.refreshTimelines()
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.stop()
        sender.delegate = nil
        services.remove(sender)
        os_log("Didn't Resolve: %{PUBLIC}@", log: .browser, type: .info, sender.description)
    }
    
    private func resolveIPv4(addresses: [Data]) -> String? {
      var result: String?

      for addr in addresses {
        let data = addr as NSData
        var storage = sockaddr_storage()
        data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)

        if Int32(storage.ss_family) == AF_INET {
          let addr4 = withUnsafePointer(to: &storage) {
            $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
              $0.pointee
            }
          }

          if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
            result = ip
            break
          }
        }
      }

      return result
    }
    
}

extension SKBrowser: SKServerFacadeDelegate {
    
    func serverDidUpdateTimelines(server: SKServerFacade) {
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.browser(strongSelf, didUpdateTimelinesForServer: server)
        }
        
    }
    
}
