//
//  MediaResponse.swift
//  RVG
//
//  Created by michael on 2017-05-23.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaChapterResponse : Mappable {
    var media : [MediaChapter]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        media  <- map["result"]
    }
    
}
