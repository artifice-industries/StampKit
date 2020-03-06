//
//  OSLog.swift
//  StampKit
//
//  Created by Sam Smallman on 22/02/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let browser = OSLog(subsystem: subsystem, category: "Browser")
    static let server = OSLog(subsystem: subsystem, category: "Server")
}
