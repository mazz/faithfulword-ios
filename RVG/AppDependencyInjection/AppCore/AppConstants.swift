import Foundation

struct StoryboardName {
    static let history = "History"
    static let main = "Root"
    static let splashScreen = "SplashScreen"
    static let noResource = "NoResource"
    static let settings = "Settings"
    static let sideMenu = "SideMenu"
    static let bibleLanguage = "SideMenu"
    static let mediaListing = "Root"
    static let mediaHistory = "History"
    static let mediaSearching = "Root"
    static let mediaDetails = "Root"
    static let categoryListing = "Root"
    static let playback = "Playback"
    static let popupPlayer = "Playback"
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

struct PopupSettings {
    static let BarStyle = "PopupSettingsBarStyle"
    static let InteractionStyle = "PopupSettingsInteractionStyle"
    static let ProgressViewStyle = "PopupSettingsProgressViewStyle"
    static let CloseButtonStyle = "PopupSettingsCloseButtonStyle"
    static let MarqueeStyle = "PopupSettingsMarqueeStyle"
    static let EnableCustomizations = "PopupSettingsEnableCustomizations"

}
