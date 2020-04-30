//
//  SKTimelineDescription.swift
//  StampKit
//
//  Created by Sam Smallman on 01/03/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

// MARK:- Overview
// A description of a timeline in StampKit.

import Foundation

/// A timeline descriptor that describes a Stamp timeline.
public struct SKTimelineDescription {
    
    public let name: String
    public let uuid: UUID
    public let password: String?
    public var hasPassword: Bool { get { return password != nil }}
    
    public init(name: String, uuid: UUID, andPassword password: String? = nil) {
        self.name = name
        self.uuid = uuid
        if let pass = password, pass.isEmpty {
            self.password = nil
        } else {
           self.password = password
        }
    }
    
    public func authorised(with password: String?) -> Bool {
        return self.hasPassword ? password == self.password : true
    }
    
}

extension SKTimelineDescription: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case name, uuid, password
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        
        let hasPassword = try container.decode(Bool.self, forKey: .password)
        if hasPassword {
            self.password = StampKitPasswordRequired
        } else {
            self.password = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodingKeys.self)
        
        try containter.encode(name, forKey: .name)
        try containter.encode(uuid, forKey: .uuid)
        try containter.encode(hasPassword, forKey: .password)
    }
}
extension SKTimelineDescription: Hashable {}
extension SKTimelineDescription: Equatable {
    
    public static func == (lhs: SKTimelineDescription, rhs: SKTimelineDescription) -> Bool {
        return lhs.name == rhs.name &&
               lhs.uuid == rhs.uuid &&
               lhs.password == rhs.password
    }
    
}


