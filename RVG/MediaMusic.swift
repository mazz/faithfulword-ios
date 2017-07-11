//
//  MediaMusic.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaMusic : Mappable, Playable {
    var localizedName : String?
    var url : String?
    var presenterName : String?
    var sourceMaterial: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName  <- map["localizedName"]
        url  <- map["url"]
        presenterName  <- map["presenterName"]
        sourceMaterial  <- map["sourceMaterial"]
    }
    
}
