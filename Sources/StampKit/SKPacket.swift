//
//  SKPacket.swift
//  StampServerKit
//
//  Created by Sam Smallman on 03/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation

public enum SKData {
    case timelines([SKTimelineDescription])
    case connect(SKStatusDescription)
    case empty
}

public struct SKPacket {
    let status: String
    let addressPattern: String
    let version: String
    let data: SKData
}

extension SKPacket: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case status, addressPattern = "address_pattern", version, data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.status = try container.decode(String.self, forKey: .status)
        self.version = try container.decode(String.self, forKey: .version)
        self.addressPattern = try container.decode(String.self, forKey: .addressPattern)
        
        switch addressPattern {
        case SKAddressParts.timelines.rawValue:
            let payload = try container.decode([SKTimelineDescription].self, forKey: .data)
            self.data = .timelines(payload)
        case _ where addressPattern.hasSuffix(SKAddressParts.connect.rawValue):
            let payload = try container.decode(SKStatusDescription.self, forKey: .data)
            self.data = .connect(payload)
        default: self.data = .empty
        }
    }
        
    public func encode(to encoder: Encoder) throws {
        
        var containter = encoder.container(keyedBy: CodingKeys.self)
        
        try containter.encode(status, forKey: .status)
        try containter.encode(addressPattern, forKey: .addressPattern)
        try containter.encode(version, forKey: .version)
        switch data {
        case .timelines(let timelines):
            try containter.encode(timelines, forKey: .data)
        case .connect(let status):
            try containter.encode(status, forKey: .data)
        case .empty: break
        }
        
    }
    
}

