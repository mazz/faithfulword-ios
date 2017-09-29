//
//  Gospel.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaGospel : Mappable, Playable {
    var sourceMaterial: String?
    var localizedName: String?
    var path: String?
    var presenterName: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        localizedName <- map["localizedName"]
        path <- map["path"]
        presenterName <- map["presenterName"]
        sourceMaterial  <- map["sourceMaterial"]
    }
    
    
}
