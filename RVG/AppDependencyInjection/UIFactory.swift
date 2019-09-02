import Foundation
import UIKit
import Swinject
import SafariServices
import MessageUI

/// Protocol facade for factory making all app-root-level related UI.
internal protocol AppUIMaking {
    func makeRoot() -> RootViewController
    func makePlayer() -> PlaybackViewController
    //    func makeInitial() -> InitialViewController
    func makeChannel(channelUuid: String) -> ChannelViewController
    func makeMainWithChannel(channelUuid: String) -> MainViewController
    func makeMain() -> MainViewController
    func makeInlineWebBrowser(url: URL) -> SFSafariViewController
    func makeMailComposer() -> MFMailComposeViewController?
    func makeOkAlert(title: String, message: String) -> UIAlertController
    func makeSideMenu() -> SideMenuViewController
//    func makeBibleLanguagePage() -> BibleLanguageViewController
    func makeBibleLanguagePage() -> RadioListViewController
    func makeMediaListing(playlistId: String, mediaCategory: MediaCategory) -> MediaListingViewController
    func makeCategoryListing(categoryType: CategoryListingType) -> CategoryListingViewController
    func makeSplashScreen() -> SplashScreenViewController

    func makePopupPlayer() -> PopupContentController
}

/// The king of UI creation in the app.
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
    func makePopupPlayer() -> PopupContentController {
        let popupContentController = PopupContentController.make(storyboardName: StoryboardName.popupPlayer)
        popupContentController.playbackViewModel = resolver.resolve(PlaybackControlsViewModel.self)
        popupContentController.downloadingViewModel = resolver.resolve(DownloadViewModel.self)
        popupContentController.userActionsViewModel = resolver.resolve(UserActionsViewModel.self)

//        demoMusicPlayerController.assetPlaybackManager = resolver.resolve(AssetPlaybackManager.self)
//        demoMusicPlayerController.remoteCommandManager = resolver.resolve(RemoteCommandManager.self)
        return popupContentController
    }

    func makeCategoryListing(categoryType: CategoryListingType) -> CategoryListingViewController {
        let categoryListingViewController = CategoryListingViewController.make(storyboardName: StoryboardName.categoryListing)
        categoryListingViewController.viewModel = resolver.resolve(CategoryListingViewModel.self, argument: categoryType)
        return categoryListingViewController
    }

    func makeSideMenu() -> SideMenuViewController {
        let sideMenuController = SideMenuViewController.make(storyboardName: StoryboardName.sideMenu)
        sideMenuController.viewModel = resolver.resolve(SideMenuViewModel.self)
        return sideMenuController
    }

    func makeBibleLanguagePage() -> RadioListViewController {
        let bibleLanguageViewController = RadioListViewController.make(storyboardName: StoryboardName.bibleLanguage)
        bibleLanguageViewController.viewModel = resolver.resolve(LanguageViewModel.self)
        return bibleLanguageViewController
    }

    func makeMediaListing(playlistId: String, mediaCategory: MediaCategory) -> MediaListingViewController {
        let mediaListingViewController = MediaListingViewController.make(storyboardName: StoryboardName.mediaListing)
        mediaListingViewController.viewModel = resolver.resolve(MediaListingViewModel.self, arguments: playlistId, mediaCategory)
        mediaListingViewController.searchViewModel = resolver.resolve(MediaSearchViewModel.self, arguments: playlistId, mediaCategory)
        mediaListingViewController.playbackViewModel = resolver.resolve(PlaybackControlsViewModel.self)
//        mediaListingViewController.downloadingService = resolver.resolve(DownloadService.self)
        mediaListingViewController.downloadListingViewModel = resolver.resolve(DownloadListingViewModel.self)

        
        let mediaSearchResultsViewController = MediaSearchResultsViewController.make(storyboardName: StoryboardName.mediaSearching)
        mediaSearchResultsViewController.viewModel = resolver.resolve(MediaSearchViewModel.self, arguments: playlistId, mediaCategory)
        
        mediaListingViewController.mediaSearchResultsViewController = mediaSearchResultsViewController

        //        mediaListingViewController.viewModel = resolver.resolve(MediaListingViewModel.self)
        return mediaListingViewController
    }

    internal func makeRoot() -> RootViewController {
        let controller = RootViewController
            .make(storyboardName: StoryboardName.main)
        controller.reachability = resolver
            .resolve(RxClassicReachable.self)
        return controller
    }

    internal func makePlayer() -> PlaybackViewController {
        let controller = PlaybackViewController
            .make(storyboardName: StoryboardName.playback)
//        controller.reachability = resolver.resolve(RxReachable.self)
        return controller
    }

    //    internal func makeInitial() -> InitialViewController {
    //        return InitialViewController
    //            .make(storyboardName: StoryboardName.main)
    //    }
    //
    
    internal func makeChannel(channelUuid: String) -> ChannelViewController {
        let controller = ChannelViewController.make(storyboardName: StoryboardName.main)
        controller.viewModel = resolver.resolve(PlaylistViewModel.self, argument: channelUuid)
        return controller
    }

    internal func makeMainWithChannel(channelUuid: String) -> MainViewController {
        let controller = MainViewController.make(storyboardName: StoryboardName.main)
        controller.viewModel = resolver.resolve(PlaylistViewModel.self, argument: channelUuid)
        return controller
    }

    internal func makeMain() -> MainViewController {
        let controller = MainViewController.make(storyboardName: StoryboardName.main)
        controller.booksViewModel = resolver.resolve(BooksViewModel.self)
        return controller
    }

    internal func makeInlineWebBrowser(url: URL) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    internal func makeMailComposer() -> MFMailComposeViewController? {
        let mailComposerVC = MFMailComposeViewController()

        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        mailComposerVC.setToRecipients(["collindanielschneide@gmail.com"])
        mailComposerVC.setSubject("Faithful Word iOS \(appVersionString) App Feedback")

        if MFMailComposeViewController.canSendMail() {
            return mailComposerVC
        } else {
            return nil
        }
    }

    internal func makeOkAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default)
        alert.addAction(okAction)
        return alert
    }

    internal func makeSplashScreen() -> SplashScreenViewController {
        return SplashScreenViewController
            .make(storyboardName: StoryboardName.splashScreen)
    }
}
