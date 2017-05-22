//
//  BookResponse.swift
//  RVG
//
//  Created by maz on 2017-05-20.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class BookResponse : Mappable {
    var books : [Book]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        books  <- map["result"]
    }
    
}
