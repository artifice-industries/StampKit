//
//  SKClientFacade.swift
//  StampServerKit
//
//  Created by Sam Smallman on 01/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import OSCKit

public class SKClientFacade {
    
    public var isConnected: Bool { get { return socket.isConnected }}
    private let socket: Socket
    
    init(socket: Socket) {
        self.socket = socket
    }
    
    internal func hasSocket(socket: Socket) -> Bool {
        return self.socket.interface == socket.interface && self.socket.host == socket.host && self.socket.port == socket.port
    }
}

extension SKClientFacade: Equatable {
    
    public static func == (lhs: SKClientFacade, rhs: SKClientFacade) -> Bool {
        return lhs.socket.interface == rhs.socket.interface &&
               lhs.socket.host == rhs.socket.host &&
               lhs.socket.port == rhs.socket.port
    }
    
}
