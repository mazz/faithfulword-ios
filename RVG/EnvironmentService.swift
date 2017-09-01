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
    
    internal var connected : Environment = Environment(url: NSURL(string: EnvironmentUrlItemKey.DevelopmentServerRootUrl.rawValue)!, name: "production")!
    
    class func sharedInstance() -> EnvironmentService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.environmentservice") {
            environmentService = EnvironmentService()

        }
        return environmentService!
    }
    
    func connectedEnvironment() -> Environment {
        return connected
    }

}
