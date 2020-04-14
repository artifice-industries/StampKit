//
//  SKConnectionStatus.swift
//  StampKit
//
//  Created by Sam Smallman on 01/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

// MARK:- Overview
// A description of the connection between a client and a timeline in StampKit.

import Foundation

/// A status descriptor that describes a clients connection with a timeline..
public struct SKStatusDescription {
    
    public let status: String
    public let uuid: UUID
    
    public init(status: String, uuid: UUID) {
        self.status = status
        self.uuid = uuid
    }
    
}

extension SKStatusDescription: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case status, uuid = "timeline_uuid"
    }

}
