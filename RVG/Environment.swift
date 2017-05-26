//
//  Environment.swift
//  RVG
//
//  Created by maz on 2017-05-20.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class Environment {
    public var baseURL : NSURL?
    public var name : String?
    
    required init?(url: NSURL, name: String) {
        baseURL = url
        self.name = name
    }

}
