//
//  Book.swift
//  RVG
//
//  Created by maz on 2017-05-20.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class Book : Mappable {
    var bookId : String?
    var title : String?
    
    required init?(map: Map) {
    
    }

    func mapping(map: Map) {
        bookId  <- map["bid"]
        title  <- map["title"]
    }
    
}
