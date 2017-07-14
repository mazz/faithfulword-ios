//
//  SessionError.swift
//  RVG
//
//  Created by michael on 2017-05-22.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

enum SessionError : Error {
    case urlNotReachable
    case urlLoadFailed
    case dataTask(String)
    case jsonParseFailed
}
