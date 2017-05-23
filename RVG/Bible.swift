//
//  Bible.swift
//  RVG
//
//  Created by maz on 2017-05-21.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class Bible {
    static var bible :  Bible?
    
    public var books : [Book]?
    public var media : [Media]?
    
    class func sharedInstance() -> Bible {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.bible") {
            bible = Bible()
            
        }
        return bible!
    }
    
}
