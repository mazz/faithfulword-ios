//
//  GospelResponse.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class GospelResponse : Mappable {
    var gospels : [Gospel]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        gospels  <- map["result"]
    }
    
}
