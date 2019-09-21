//
//  String+NumberFormatting.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-21.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

// https://stackoverflow.com/a/49343299

public extension Int64  {
    func fileSizeString() -> String {
//        if let asInteger: Int64 = Int64(self) {
            if self >= 0 {
                // bytes
                if self < 1023 {
                    return String(format: "%lu bytes", CUnsignedLong(self))
                }
                // KB
                var floatSize = Float(self / 1024)
                if floatSize < 1023 {
                    return String(format: "%.1f KB", floatSize)
                }
                // MB
                floatSize = floatSize / 1024
                if floatSize < 1023 {
                    return String(format: "%.1f MB", floatSize)
                }
                // GB
                floatSize = floatSize / 1024
                return String(format: "%.1f GB", floatSize)
            } else { // return 0 bytes if negative
                return String(format: "%lu bytes", CUnsignedLong(0))
            }
//        } else { // return 0 bytes if something went wrong
//            return String(format: "%lu bytes", CUnsignedLong(0))
//        }
    }
}
