//
//  Device.swift
//  RVG
//
//  Created by michael on 2017-05-22.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class Device {
    func preferredLanguageIdentifier() -> (String) {
        return Locale.preferredLanguages[0]
    }
    
    func userAgent() -> (String) {
        let webView: UIWebView = UIWebView.init(frame: .zero)
        let userAgent: String = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")!
        return userAgent
    }
    
    func platform() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
}
