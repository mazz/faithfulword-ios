import Foundation
import WebKit

internal protocol DeviceInfoProviding {
    var userAgent: String { get }
}

internal final class DeviceInfoProvider: DeviceInfoProviding {
    
    internal init() {
        self.userAgent
    }
    
    internal var userAgent: String {
        let webView: UIWebView = UIWebView.init(frame: .zero)
        let userAgent: String = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")!
        return userAgent
        
//        var userAgent: String!
//        var webView: WKWebView!
//
//        let semaphore = DispatchSemaphore(value: 0)
//
//        DispatchQueue.main.async {
//            webView = WKWebView.init(frame: .zero)
//            webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
//                if error != nil {
//                    semaphore.signal()
//                    return
//                }
//                if let ua = result as? String {
//                    webView.customUserAgent = ua
//                    userAgent = ua
//                    semaphore.signal()
//                }
//            }
//        }
//
//        semaphore.wait()
//        return userAgent

    }
}
