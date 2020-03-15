import Foundation
import WebKit

internal protocol DeviceInfoProviding {
    var userAgent: String? { get }
}

internal final class DeviceInfoProvider: DeviceInfoProviding {
    var webView: WKWebView

    internal init() {
        webView = WKWebView.init(frame: .zero)
        self.userAgent
    }

    internal var userAgent: String? {
        var userAgent: String? = nil
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if error != nil {
                    print("Error occured to get userAgent")
                    return
                }
                if let unwrappedUserAgent = result as? String {
                    userAgent = unwrappedUserAgent
                    UserDefaults.standard.set(userAgent, forKey: "device_user_agent")
                }
                else {
                    print("Failed to get userAgent")
                    userAgent = nil
                }
            }
        }
        return userAgent
    }
}
