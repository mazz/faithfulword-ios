//
//  Gospel.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaGospel : Mappable {
    var localizedName : String?
    var url : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName  <- map["localizedName"]
        url  <- map["url"]
    }
    
    
}
