import Foundation
import WebKit

internal protocol DeviceInfoProviding {
    var userAgent: String { get }
}

internal final class DeviceInfoProvider: DeviceInfoProviding {
    var webView: WKWebView

    internal init() {
        webView = WKWebView.init(frame: .zero)
        self.userAgent
    }

    internal var userAgent: String {
        var userAgent: String = "iOS"
        
        if let ua: String = UserDefaults.standard.object(forKey: "device_user_agent") as? String {
            return ua
        }
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if error != nil {
                    print("Error occured to get userAgent")
                    userAgent = "iOS"
                }
                if let unwrappedUserAgent = result as? String {
                    userAgent = unwrappedUserAgent
                    UserDefaults.standard.set(userAgent, forKey: "device_user_agent")
                }
                else {
                    print("Failed to get userAgent")
                    userAgent = "iOS"
                }
            }
        }
        return userAgent
    }
}
