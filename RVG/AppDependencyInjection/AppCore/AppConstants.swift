import Foundation

struct StoryboardName {
    static let main = "Root"
    static let splashScreen = "SplashScreen"
    static let settings = "Settings"
    static let sideMenu = "SideMenu"
    static let bibleLanguage = "SideMenu"
    static let mediaListing = "Root"
    static let categoryListing = "Root"
    static let playback = "Playback"
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

