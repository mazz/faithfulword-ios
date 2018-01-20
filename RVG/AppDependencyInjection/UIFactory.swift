import Foundation
import UIKit
import Swinject

/// Protocol facade for factory making all app-root-level related UI.
internal protocol AppUIMaking {
    func makeRoot() -> RootViewController
//    func makeInitial() -> InitialViewController
    func makeMain() -> MainViewController
    func makeMediaListing(playlistId: String, mediaType: MediaType) -> MediaListingViewController
    func makeSplashScreen() -> SplashScreenViewController
}

/// Protocol facade for factory making all settings related UI.
internal protocol SettingsUIMaking {
//    func makeSettings() -> SettingsViewController
}

/// The king of UI creation in GoseMobileSample app.
/// Having a single factory fronted by facades avoids circular-dependency problems that often arise with multiple
/// factories.  This is because the nature of interactions between screens are not hierarchical in general, and
/// sometimes inverts at different points in the app.
internal final class UIFactory: UIMaking {
    private let resolver: Resolver
    public required init(resolver: Resolver) {
        self.resolver = resolver
    }
    private let bundle: Bundle? = Bundle.main
}

// MARK: <AppUIMaking>
extension UIFactory: AppUIMaking {
    func makeMediaListing(playlistId: String, mediaType: MediaType) -> MediaListingViewController {
        let mediaListingViewController = MediaListingViewController.make(storyboardName: StoryboardName.mediaList)
        mediaListingViewController.viewModel = resolver.resolve(MediaListingViewModel.self, arguments: playlistId, mediaType)
//        mediaListingViewController.viewModel = resolver.resolve(MediaListingViewModel.self)
        return mediaListingViewController
    }

    internal func makeRoot() -> RootViewController {
        let controller = RootViewController
            .make(storyboardName: StoryboardName.main)
        controller.reachability = resolver
            .resolve(RxReachable.self)
        return controller
    }
    
//    internal func makeInitial() -> InitialViewController {
//        return InitialViewController
//            .make(storyboardName: StoryboardName.main)
//    }
//
    internal func makeMain() -> MainViewController {
        let controller = MainViewController
            .make(storyboardName: StoryboardName.main)
        controller.viewModel = resolver
            .resolve(MainViewModel.self)
        return controller
    }

    internal func makeSplashScreen() -> SplashScreenViewController {
        return SplashScreenViewController
            .make(storyboardName: StoryboardName.splashScreen)
    }
}

// MARK: <SettingsUIMaking>
//extension UIFactory: SettingsUIMaking {
//    internal func makeSettings() -> SettingsViewController {
//        let controller =  SettingsViewController
//            .make(storyboardName: StoryboardName.settings)
//        controller.viewModel = resolver
//            .resolve(SettingsViewModel.self)
//        return controller
//    }
//}

