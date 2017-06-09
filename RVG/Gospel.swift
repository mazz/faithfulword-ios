//
//  Gospel.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class Gospel : Mappable {
    var gospelId : String?
    var title : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        gospelId  <- map["gid"]
        title  <- map["title"]
    }
    
    
}
