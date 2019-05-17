//
//  AppVersionResponse.swift
//  
//
//  Created by maz on 2017-11-25.
//

import Foundation

public struct AppVersionResponse: Codable {
    public var result: [AppVersion]
    public var status: String
    public var version: String
}

