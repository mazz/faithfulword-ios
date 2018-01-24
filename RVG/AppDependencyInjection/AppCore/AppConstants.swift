import Foundation

struct StoryboardName {
    static let main = "Root"
    static let splashScreen = "SplashScreen"
    static let settings = "Settings"
    static let deviceSelection = "DeviceSelection"
    static let mediaList = "Root"
}

struct AnimationConstants {
    static let splashScreenTransition = 7.0
}

public struct ModuleInfo {
    private static let bundleIdentifier = "com.kjvrvg-ios"
    private static let cocoapodsBundleIdentifier = "org.cocoapods.kjvrvg-ios"
}

extension ModuleInfo {
    public static var bundle: Bundle {
        return Bundle.main
    }
}
