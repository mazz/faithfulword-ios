//
//  RootUrlKey.swift
//  RVG
//
//  Created by maz on 2017-07-15.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

extension EnvironmentUrlItemKey {
    static var DevelopmentFileStorageRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://d2v5mbm9qwqitj.cloudfront.net")
    }
    static var DevelopmentServerRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://japheth.ca")
    }
    static var S3BaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://rvg-tracks-cdn.s3.amazonaws.com")
    }
    static var S3WestBaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://s3-us-west-2.amazonaws.com/rvg-tracks-cdn")
    }
}