//
//  RootUrlItemKey.swift
//  RVG
//
//  Created by maz on 2017-07-15.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

/**
 A custom struct holds keys
 Create extension to add keys
 
 extension QuickLinkItemKey {
 static var Accounts : QuickLinkItemKey {
 return QuickLinkItemKey(rawValue: "Quicklink.Accounts")
 }
 ...
 }
 */

public struct EnvironmentUrlItemKey: RawRepresentable, Equatable, Hashable, Comparable {
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    // MARK: Hashable
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    // MARK: Comparable
    public static func < (lhs: EnvironmentUrlItemKey, rhs: EnvironmentUrlItemKey) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
