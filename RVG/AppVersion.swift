//
//  AppVersion.swift
//  AllScripture
//
//  Created by maz on 2017-11-25.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

public struct AppVersion: Codable {
    public var uuid: String
    public var supported: Bool
    public var versionNumber: String
}

