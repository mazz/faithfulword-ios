//
//  Media.swift
//  RVG
//
//  Created by michael on 2017-05-23.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaChapter : Mappable, Playable {
    var localizedName : String?
    var url : String?
    var presenterName : String?
    var sourceMaterial : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName  <- map["localizedName"]
        url  <- map["url"]
        presenterName  <- map["presenterName"]
        sourceMaterial  <- map["sourceMaterial"]
    }
    
}
