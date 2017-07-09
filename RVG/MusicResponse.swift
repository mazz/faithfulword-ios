//
//  MusicResponse.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MusicResponse : Mappable {
    var music : [Music]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        music  <- map["result"]
    }
    
}
