//
//  String+Hashing.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation

public extension String {
    var sha512Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        if let data = self.data(using: String.Encoding.utf8) {
            let value =  data as NSData
            CC_SHA512(value.bytes, CC_LONG(data.count), &digest)

        }
        var digestHex = ""
        for index in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }

        return digestHex
    }


    var sha512: [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        if let data = self.data(using: String.Encoding.utf8 , allowLossyConversion: true) {
            let value =  data as NSData
            CC_SHA512(value.bytes, CC_LONG(value.length), &digest)
        }

        return digest
    }

    var sha512Base64: String {
        let digest = NSMutableData(length: Int(CC_SHA512_DIGEST_LENGTH))!
        if let data = self.data(using: String.Encoding.utf8) {

            let value =  data as NSData
            let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: digest.length)
            CC_SHA512(value.bytes, CC_LONG(data.count), uint8Pointer)

        }
        return digest.base64EncodedString(options: NSData.Base64EncodingOptions([]))
    }
    /*
     let vad = sha512Hex(string: "8yOrBmkd")
     DDLogDebug(vad)

     let digestRaw = sha512(string:"8yOrBmkd")
     DDLogDebug("decimal array:\n\(digestRaw)")
     DDLogDebug("hexadecimal:\n\(NSData(bytes:digestRaw, length:digestRaw.count).description)")

     let digestBase64 = sha512Base64(string:"8yOrBmkd")
     DDLogDebug("Base64:\n\(digestBase64)")
     */

    var MD5: Data {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))

        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }

        return digestData
    }

    var MD5hex: String {
        let md5Data = self.MD5

        return md5Data.map { String(format: "%02hhx", $0) }.joined()
    }

    /*
     let md5Data = MD5(string:"Hello")

     let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
     DDLogDebug("md5Hex: \(md5Hex)")

     let md5Base64 = md5Data.base64EncodedString()
     DDLogDebug("md5Base64: \(md5Base64)")

     */
}

