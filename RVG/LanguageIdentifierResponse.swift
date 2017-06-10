//
//  LanguageIdentifierResponse.swift
//  RVG
//
//  Created by maz on 2017-06-10.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class LanguageIdentifierResponse : Mappable {
    var languageIdentifiers : [LanguageIdentifier]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        languageIdentifiers  <- map["result"]
    }
    
}
