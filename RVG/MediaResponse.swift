//
//  MediaResponse.swift
//  RVG
//
//  Created by michael on 2017-05-23.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaResponse : Mappable {
    var media : [Media]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        media  <- map["result"]
    }
    
}
