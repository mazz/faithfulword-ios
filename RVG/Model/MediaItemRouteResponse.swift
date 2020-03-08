//
//  MediaItemRouteResponse.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-06.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation

public struct MediaItemRouteResponse: Codable {
    public var result: MediaItem
    public var status: String
    public var version: String
}
