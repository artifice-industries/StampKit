//
//  SKBrowser.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

protocol SKBrowserDelegate {
    func browser(_: SKBrowser, didUpdateTimelinesForServer server: SKServer)
    func browser(_: SKBrowser, didUpdateServers servers: Set<SKServer>)
}

public class SKBrowser: NSObject {
    
    var netServiceDomainsBrowser: NetServiceBrowser?
    var netServiceTCPBrowser: NetServiceBrowser?
    var services: Set<NetService> = []
    var delegate: SKBrowserDelegate?
    var servers: Set<SKServer> = []
    var running: Bool = false
    var refreshTimer: Timer?
    
    deinit {
        stop()
    }
    
    public func start() {
        if running {
            os_log("Starting Browser - already running", log: .browser, type: .info)
        } else {
            os_log("Starting Browser", log: .browser, type: .info)
        }
        
        if !running {
            netServiceDomainsBrowser = NetServiceBrowser()
            netServiceDomainsBrowser?.delegate = self
            netServiceDomainsBrowser?.searchForBrowsableDomains()
        }
    }
    
    public func stop() {
        
        disableAutoRefresh()
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
    
    func enableAutoRefresh(with interval: TimeInterval) {
        if refreshTimer == nil {
            refreshTimer = Timer(timeInterval: interval, target: self, selector: #selector(refreshTimelines(timer:)), userInfo: nil, repeats: true)
            refreshTimer?.tolerance = interval * 0.1
        }
    }
    
    private func disableAutoRefresh() {
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
        for service in netServices {
            guard let addresses = service.addresses, !addresses.isEmpty else { continue }
            service.resolve(withTimeout: 5.0)
        }
    }
    
    func server(for service: NetService) -> SKServer? {
        return servers.first(where: { $0.service === service })
    }
    
    func server(for hostName: String) -> SKServer? {
        return servers.first(where: { $0.service?.hostName == hostName })
    }
    
}

extension SKBrowser: NetServiceBrowserDelegate {
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        if browser == netServiceDomainsBrowser {
            os_log("Starting Bonjour - browsable domains search", log: .browser, type: .info)
        } else if browser == netServiceTCPBrowser {
            os_log("Starting Bonjour (TCP) - %{PUBLIC}@", log: .browser, type: .info, StampKitBonjourServiceDomain)
        } else {
            os_log("netServiceBrowserWillSearch: %{PUBLIC}@", log: .browser, type: .info, browser.description)
        }
        
        running = browser == netServiceDomainsBrowser
        delegate?.browser(self, didUpdateServers: servers)
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        if browser == netServiceDomainsBrowser {
            os_log("Stopping Bonjour - browsable domains search", log: .browser, type: .info)
        } else if browser == netServiceTCPBrowser {
            os_log("Stopping Bonjour (TCP) - %{PUBLIC}@", log: .browser, type: .info, StampKitBonjourServiceDomain)
        } else {
            os_log("netServiceBrowserDidStopSearch: %{PUBLIC}@", log: .browser, type: .info, browser.description)
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
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        os_log("netSeviceBrowser.didNotSearch: %{PUBLIC}@", log: .browser, type: .info, browser.description)
        for error in errorDict {
            os_log("error: %{PUBLIC}@", log: .browser, type: .info, error.value)
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        os_log("netSeviceBrowser.didFindDomain: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, domainString, moreComing)
        guard netServiceTCPBrowser == nil, domainString == StampKitBonjourServiceDomain else { return }
        netServiceTCPBrowser = NetServiceBrowser()
        netServiceTCPBrowser?.delegate = self
        netServiceTCPBrowser?.searchForServices(ofType: StampKitBonjourTCPServiceType, inDomain: StampKitBonjourServiceDomain)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        os_log("netSeviceBrowser.didFindService: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, service.description, moreComing)
        service.delegate = self
        services.insert(service)
        
        // Multiple calls cancel previous requests to ensure resolving only begins once (i.e if moreComming == true)
        setNeedsBeginResolvingNetServices()
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        os_log("netSeviceBrowser.didRemoveService: %{PUBLIC}@ moreComing: %{PUBLIC}@", log: .browser, type: .info, service.description, moreComing)
        
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
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        os_log("netSevice.didResolveAddress: %{PUBLIC}@", log: .browser, type: .info, sender.description)
        guard sender.port > 0 else { return }
        
        var hostName = sender.hostName
        
        if hostName == nil || hostName?.isEmpty == true {
            guard let addresses = sender.addresses, let ipAddress = resolveIPv4(addresses: addresses) else { return }
            hostName = ipAddress
        }
        
        guard let name = hostName else { return }
        
        let server = SKServer(host: name, port: sender.port)
        server.delegate = self
        server.service = sender
        
        // Once resolved, we can remove the net service from our locals records. The SKServer will still hold on to it.
        sender.delegate = nil
        services.remove(sender)
        
        servers.insert(server)
        
        DispatchQueue.main.async { [weak self] in
           guard let strongSelf = self else { return }
            strongSelf.delegate?.browser(strongSelf, didUpdateServers: strongSelf.servers)
        }
        
        server.refreshTimelines()
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.stop()
        sender.delegate = nil
        services.remove(sender)
        os_log("netSevice.didNotResolve: %{PUBLIC}@", log: .browser, type: .info, sender.description)
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

extension SKBrowser: SKServerDelegate {
    
    func serverDidUpdateTimelines(server: SKServer) {
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.browser(strongSelf, didUpdateTimelinesForServer: server)
        }
        
    }
    
}
