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
    var localizedName : String?
    var path : String?
    var languageIdentifier : String?
    var presenterName : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName <- map["localizedName"]
        path <- map["path"]
        languageIdentifier <- map["languageIdentifier"]
        presenterName <- map["presenterName"]
    }
}
