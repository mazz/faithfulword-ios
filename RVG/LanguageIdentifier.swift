//
//  LanguageIdentifier.swift
//  RVG
//
//  Created by maz on 2017-06-10.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class LanguageIdentifier : Mappable {
    var languageIdentifier : String?
    var supported : Bool?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        languageIdentifier  <- map["languageIdentifier"]
        supported <- map["supported"]
    }
    
    
}
