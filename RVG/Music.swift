//
//  Music.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class Music : Mappable {
    var musicId : String?
    var title : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        musicId  <- map["mid"]
        title  <- map["title"]
    }
    
}
