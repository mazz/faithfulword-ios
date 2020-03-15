
import Foundation
import WebKit

class Device {
    class func preferredLanguageIdentifier() -> (String) {
        return Locale.preferredLanguages[0]
    }
    
    class func userAgent() -> (String) {
//        let webView: UIWebView = UIWebView.init(frame: .zero)
//        let userAgent: String = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")!
//        return userAgent
        var userAgent: String!
        var webView: WKWebView!

        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            webView = WKWebView.init(frame: .zero)
            webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if error != nil {
                    semaphore.signal()
                    return
                }
                if let ua = result as? String {
                    webView.customUserAgent = ua
                    userAgent = ua
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        return userAgent
    }
    
    class func platform() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
}
