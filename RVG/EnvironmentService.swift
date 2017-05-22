//
//  EnvironmentService.swift
//  RVG
//
//  Created by maz on 2017-05-20.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class EnvironmentService {
    static var environmentService :  EnvironmentService?
    
    internal var connected : Environment?
    
    class func sharedInstance() -> EnvironmentService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.environmentservice") {
            environmentService = EnvironmentService()

        }
        return environmentService!
    }
    
    func connectedEnvironment() -> Environment {
        
        if let environment = Environment(url: NSURL(string: "https://japheth.ca")!, name: "development") {
            connected = environment
        }
        return connected!
    }

}
