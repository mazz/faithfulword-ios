//
//  Formatter+Date.swift
//  EvaluApp
//
//  Created by Michael on 2019-11-05.
//  Copyright © 2019 ilearningsolutions.ca. All rights reserved.
//

import Foundation

extension Formatter {
    static let iso8601 = ISO8601DateFormatter([.withInternetDateTime])
}

