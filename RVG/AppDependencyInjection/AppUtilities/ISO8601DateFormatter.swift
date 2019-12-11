//
//  ISO8601DateFormatter.swift
//  EvaluApp
//
//  Created by Michael on 2019-11-05.
//  Copyright © 2019 ilearningsolutions.ca. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}
