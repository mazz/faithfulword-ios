//
//  Media.swift
//  RVG
//
//  Created by michael on 2017-05-23.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaChapter : Mappable {
    var localizedName : String?
    var url : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName  <- map["localizedName"]
        url  <- map["url"]
    }
    
}
