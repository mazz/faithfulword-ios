import UIKit
import RxSwift
import SafariServices
import LNPopupController
import SideMenu
import os.log

internal enum MainRevealState {
    case closed
    case open
}

/// Coordinator in charge of all navigation in authenticated state.
internal final class MainCoordinator: NSObject {
    static let mainCoordinatorFlowDidCompleteNotification = Notification.Name("mainCoordinatorFlowDidCompleteNotification")

    // MARK: Fields
    
    public var mainNavigationController: UINavigationController!
    public var popupController: PopupContentController?

    private var sideMenuController: SideMenuViewController?
    internal var gospelChannelUuid: String?
    internal var preachingChannelUuid: String?
    internal var musicChannelUuid: String?
    internal var bibleChannelUuid: String?
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private let bag = DisposeBag()
    private var mediaRouteListenerBag = DisposeBag()
    private var mediaUniversalLinkListenerBag = DisposeBag()
    private let mediaRouteHandler: MediaRouteHandling
    private let mediaUniversalLinkHandler: MediaUniversalLinkHandling
    
    private var deviceContextBag = DisposeBag()
    private var mainFlowCompletion: FlowCompletion!
    
    // hamburger
    private var mainViewRevealed: MainRevealState = .closed
    //    private var originalMenuFrame: CGRect!
    
    // MARK: Dependencies
    
    internal let appUIMaking: AppUIMaking
    //    private let resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>
    private let resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
    //    internal let resettableCategoryListingCoordinator: Resettable<CategoryListingCoordinator>
    internal let resettableChannelCoordinator: Resettable<ChannelCoordinator>
    private let resettableSideMenuCoordinator: Resettable<SideMenuCoordinator>
    private let resettableBibleLanguageCoordinator: Resettable<BibleLanguageCoordinator>
    private let resettableHistoryCoordinator: Resettable<HistoryCoordinator>
    private let resettableMediaRouteCoordinator: Resettable<MediaRouteCoordinator>
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    private let resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>
    private let reachability: RxClassicReachable
    
    private let productService: ProductServicing
    private let historyService: HistoryServicing

    //    private let resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
    
    //    private let resettableDeviceSelectionCoordinator: Resettable<DeviceSelectionCoordinator>
    //    private let resettableSectionalNavigatorCoordinator: Resettable<SectionalNavigatorCoordinator>
    //    private let resettableControlCentreCoordinator: Resettable<ControlCentreCoordinator>
    //    private let presentBlurAnimationController: UIViewControllerAnimatedTransitioning = PresentBlurAnimationController()
    //    private let dismissBlurAnimationController: UIViewControllerAnimatedTransitioning = DismissBlurAnimationController()
    //    private let deviceManager: DeviceManaging
    
    internal init(appUIMaking: AppUIMaking,
                  //                  resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
        resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>,
        resettableSideMenuCoordinator: Resettable<SideMenuCoordinator>,
        resettableChannelCoordinator: Resettable<ChannelCoordinator>,
        resettableBibleLanguageCoordinator: Resettable<BibleLanguageCoordinator>,
        resettableHistoryCoordinator: Resettable<HistoryCoordinator>,
        resettableMediaRouteCoordinator: Resettable<MediaRouteCoordinator>,
        resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>,
        resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>,
        reachability: RxClassicReachable,
        mediaRouteHandler: MediaRouteHandling,
        mediaUniversalLinkHandler: MediaUniversalLinkHandling,
        productService: ProductServicing,
        historyService: HistoryServicing
        
        //                  resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>,
        //                  resettableDeviceSelectionCoordinator: Resettable<DeviceSelectionCoordinator>,
        //                  resettableSectionalNavigatorCoordinator: Resettable<SectionalNavigatorCoordinator>,
        //                  resettableControlCentreCoordinator: Resettable<ControlCentreCoordinator>,
        //                  deviceManager: DeviceManaging
    ) {
        self.appUIMaking = appUIMaking
        self.resettableMediaListingCoordinator = resettableMediaListingCoordinator
        self.resettableSideMenuCoordinator = resettableSideMenuCoordinator
        self.resettableChannelCoordinator = resettableChannelCoordinator
        self.resettableBibleLanguageCoordinator = resettableBibleLanguageCoordinator
        self.resettableHistoryCoordinator = resettableHistoryCoordinator
        self.resettableMediaRouteCoordinator = resettableMediaRouteCoordinator
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
        self.resettableNoResourceCoordinator = resettableNoResourceCoordinator
        self.reachability = reachability
        self.mediaRouteHandler = mediaRouteHandler
        self.mediaUniversalLinkHandler = mediaUniversalLinkHandler

        self.productService = productService
        self.historyService = historyService

        //        self.resettableSplashScreenCoordinator = resettableSplashScreenCoordinator
        
        //        self.resettableDeviceNowPlayingCoordinator = resettableDeviceNowPlayingCoordinator
        //        self.resettableDeviceSelectionCoordinator = resettableDeviceSelectionCoordinator
        //        self.resettableSectionalNavigatorCoordinator = resettableSectionalNavigatorCoordinator
        //        self.resettableControlCentreCoordinator = resettableControlCentreCoordinator
        //        self.deviceManager = deviceManager
    }
}

// MARK: <NavigationCoordinating>
extension MainCoordinator: NavigationCoordinating {
    /// Creates and sets up the mainViewController and sets it as the root of mainNavigationController,
    /// and stores the completion closure to be executed when the flow is complete.
    ///
    /// - Parameters:
    ///   - setup: Closure that passes the initial main navigation-controller to the caller.
    ///   - completion: Called when main flow completed (e.g. logout).
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        
        // by this point we are sure that we are:
        // -    authenticated
        // -    fetched the default org
        // -    fetched all the channels of the default org
        
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown, .notReachable, .reachable(_):
                    os_log("mediaroutecoordinator %@", log: OSLog.data, String(describing: self.reachability.status.value))
                }
            }).disposed(by: bag)
        
        
        self.resettableNoResourceCoordinator.value.tryAgainTapped
            .asObservable()
            .next {
                switch self.networkStatus.value {
                case .unknown, .notReachable:
                    os_log("not reachable, no change", log: OSLog.data)
                case .reachable(_):
                    self.mainNavigationController.popViewController(animated: false)
                    self.resettableBibleLanguageCoordinator.value.flow(with: { viewController in
                        
                        self.mainNavigationController.pushViewController(
                            viewController,
                            animated: true
                        )
                        //            self.mainNavigationController.present(viewController, animated: true)
                    }, completion: { _ in
                        self.mainNavigationController.dismiss(animated: true)
                        self.resettableBibleLanguageCoordinator.reset()
                        //            self.resettableSplashScreenCoordinator.reset()
                        
                    }, context: .push(onto: self.mainNavigationController))
                }
        }.disposed(by: bag)

        // we now need to load all the playlists of a channel of our choice
        // for now, let's get the Bible channel and then pass the playlist that contains
        // the old and new testaments
        
        var mainViewController: MainViewController!
        
        if let bibleChannelUuid: String = self.bibleChannelUuid {
            DDLogDebug("bibleChannelUuid: \(bibleChannelUuid)")
            
            mainViewController = appUIMaking.makeMainWithChannel(channelUuid: bibleChannelUuid)
            attachRootMenuAction(to: mainViewController)
            attachSettingAction(to: mainViewController)
            
            mainNavigationController = UINavigationController(rootViewController: mainViewController)
            
        } else {
            DDLogError("⚠️ fatal error, need a Bible Channel! Bailing!")
            completion(FlowCompletionType.error)
        }
        
        // keep original state of hamburger so we know what frame to toggle back to
        //        originalMenuFrame = self.mainNavigationController.view.frame
        
        handle(eventsFrom: mainViewController.viewModel)
        
        handleMediaRouteEvents()
        handleMediaUniversalLinkEvents()
        
        // could not do this in appcoordinator because there
        // is no navigation controller there. so starting it here
        // in maincoordinator
        
        gotoPlaybackHistory()

        setup(mainNavigationController)
        
        //        let nowPlayingBar = DeviceNowPlayingBarView.fromUiNib()
        
        //        nowPlayingBar.translatesAutoresizingMaskIntoConstraints = false
        //        mainNavigationController.view.addSubview(nowPlayingBar)
        
        //        mainNavigationController.view.embedFilling(subview: nowPlayingBar)
        
        //        mainNavigationController.embed(playbackViewController, in: mainNavigationController.view, withAnimation: AppAnimations.fade)
        
        
        
        //        resettableSectionalNavigatorCoordinator.value.flow(with: { sectionalNavigator in
        //            mainViewController.plant(sectionalNavigator)
        //        }, completion: { [unowned self] _ in
        //            self.resettableSectionalNavigatorCoordinator.reset()
        //        }, context: .other)
        mainFlowCompletion = completion
    
//        NotificationCenter.default.post(MainCoordinator.mainCoordinatorFlowDidCompleteNotification)
        NotificationCenter.default.post(name: MainCoordinator.mainCoordinatorFlowDidCompleteNotification, object: nil)
    }
    
    private func attachRootMenuAction(to viewController: UIViewController) {
        let hamburger = UIBarButtonItem.hamburger()
        
        hamburger.rx.tap.asObservable().subscribe(onNext: { [unowned self] in
            self.goToHamburger()
        }).disposed(by: bag)
        viewController.navigationItem.leftBarButtonItem = hamburger
    }
    
    private func attachSettingAction(to viewController: UIViewController) {
        //        let close = UIBarButtonItem.settings()
        //        close.rx.tap.asObservable().subscribe(onNext: { [unowned self] in
        //            self.goToSettings()
        //        }).disposed(by: bag)
        //        viewController.navigationItem.rightBarButtonItem = close
    }
    
    private func gotoPlaybackHistory() {
                self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
                    // do nothing because the bottom popup should appear
                    // when the playbackViewController loads
                    
                    
                    // get the playback history
                    if let popupController: PopupContentController = playbackViewController as? PopupContentController {
                        self.popupController = popupController
                        
                        self.historyService.fetchPlaybackHistory(limit: 1)
                            .subscribe(onSuccess: { playables in
                                // this assignment is meant to initiate the entire playbackAsset to assetPlaybackManager
                                // assignment and loading of the historyPlayable
                                
                                if let playable = playables.first {
                                    popupController.shouldAutostartPlayback = false
                                    popupController.playbackViewModel.selectedPlayable.value = playable
                                    
                                    if let thumbImage = UIImage(named: "creation") {
                                        popupController.popupItem.title = playable.localizedname
                                        popupController.popupItem.subtitle = playable.presenter_name ?? "Unknown"
                                        popupController.popupItem.image = thumbImage
                                        //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                                        //                popupController.fullAlbumArtImageView.image = thumbImage
                                        popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "").l10n()
                                        
                                        if let navigationController = self.mainNavigationController {
                                            navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "").l10n()
                                            navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                                            navigationController.popupBar.imageView.layer.cornerRadius = 5
                                            if navigationController.popupContent == nil {
                                                os_log("MainCoordinator navigationController.popupContent: %{public}@", log: OSLog.data, String(describing: navigationController.popupContent))
                                                navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
                                            }
                                        }
                                    }
                                }
                            })
                            .disposed(by: bag)
                    }
                    
                }, completion: { _ in
                    self.mainNavigationController!.dismiss(animated: true)
                    self.resettablePlaybackCoordinator.reset()
                    
                }, context: .other)

    }
    
    private func goToPlaylist(_ forPlaylistUuid: String, _ mediaCategory: String) {
        DDLogDebug("goToPlaylist: \(forPlaylistUuid), mediaCategory: \(mediaCategory)")
        // do not use a new flow, because Chapters is part of the Book flow AFAICT
        //        self.resettableSplashScreenCoordinator.value.flow(with: { viewController in
        
        self.resettableMediaListingCoordinator.value.playlistId = forPlaylistUuid
        self.resettableMediaListingCoordinator.value.mediaCategory = MediaCategory(rawValue: mediaCategory)
        self.resettableMediaListingCoordinator.value.flow(with: { viewController in
            
            self.mainNavigationController.pushViewController(
                viewController,
                animated: true
            )
            //            self.mainNavigationController.present(viewController, animated: true)
        }, completion: { _ in
            self.mainNavigationController.dismiss(animated: true)
            self.resettableMediaListingCoordinator.reset()
            //            self.resettableSplashScreenCoordinator.reset()
            
        }, context: .push(onto: self.mainNavigationController))
    }
    
    private func goToBook(for bookUuid: String) {
        // do not use a new flow, because Chapters is part of the Book flow AFAICT
        //        self.resettableSplashScreenCoordinator.value.flow(with: { viewController in
        
        self.resettableMediaListingCoordinator.value.playlistId = bookUuid
        self.resettableMediaListingCoordinator.value.mediaCategory = .bible
        self.resettableMediaListingCoordinator.value.flow(with: { viewController in
            
            self.mainNavigationController.pushViewController(
                viewController,
                animated: true
            )
            //            self.mainNavigationController.present(viewController, animated: true)
        }, completion: { _ in
            self.mainNavigationController.dismiss(animated: true)
            self.resettableMediaListingCoordinator.reset()
            //            self.resettableSplashScreenCoordinator.reset()
            
        }, context: .push(onto: self.mainNavigationController))
    }
    
    func swapInSideMenuFlow() {
        resettableSideMenuCoordinator.value.flow(with: { [weak self] sideMenuViewController in
            
            if let strongSelf = self,
                let controller = sideMenuViewController as? SideMenuViewController {
                strongSelf.sideMenuController = controller
                handle(eventsFrom: (strongSelf.sideMenuController?.viewModel)!)
                
                let menu = SideMenuNavigationController(rootViewController: controller)
                var settings = SideMenuSettings()
                settings.menuWidth = controller.view.frame.width*0.7
                settings.statusBarEndAlpha = 0
                let menuPresentationStyle: SideMenuPresentationStyle = .viewSlideOut
                menuPresentationStyle.onTopShadowOpacity = 0.75
                settings.completeGestureDuration = 0.25
                settings.completionCurve = .easeInOut
                settings.dismissDuration = 0.25
                settings.presentationStyle = menuPresentationStyle
                menu.settings = settings
                menu.leftSide = true
                
                SideMenuManager.default.leftMenuNavigationController = menu
                SideMenuManager.default.addPanGestureToPresent(toView: strongSelf.mainNavigationController!.navigationBar)
                SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: strongSelf.mainNavigationController!.view)
                strongSelf.mainNavigationController.present(menu, animated: true, completion: nil)
            }
            
            }, completion: { [weak self] _ in
                
                if let strongSelf = self {
                    strongSelf.mainNavigationController.dismiss(animated: true)
                    strongSelf.resettableSideMenuCoordinator.reset()
                }
            }, context: .present)
    }
    
    func goToHistoryFlow() {
        self.mainNavigationController.dismiss(animated: true, completion: {
            self.resettableHistoryCoordinator.value.navigationController = self.mainNavigationController
            
            self.resettableHistoryCoordinator.value.flow(with: { viewController in
                
                self.mainNavigationController.pushViewController(
                    viewController,
                    animated: true
                )
                //            self.mainNavigationController.present(viewController, animated: true)
            }, completion: { _ in
                self.mainNavigationController.dismiss(animated: true)
                self.resettableHistoryCoordinator.reset()
                //            self.resettableSplashScreenCoordinator.reset()
                
            }, context: .push(onto: self.mainNavigationController))
        })
    }
    
    func goToBibleLanguageFlow() {
        self.mainNavigationController.dismiss(animated: true, completion: {
            
            switch self.networkStatus.value {
            case .unknown, .notReachable:
                self.resettableNoResourceCoordinator.value.networkStatus = self.networkStatus.value
                self.resettableNoResourceCoordinator.value.viewControllerSiblingStatus = .pushed
                
                self.resettableNoResourceCoordinator.value.flow(with: { [unowned self] noResourceViewController in
                    
                    self.mainNavigationController.pushViewController(
                        noResourceViewController,
                        animated: true
                    )
                    
                    }, completion: { [unowned self] _ in
                        //                    self.swapInMainFlow()
                        self.resettableNoResourceCoordinator.reset()
                    }, context: .other)
            case .reachable(_):
                self.resettableBibleLanguageCoordinator.value.flow(with: { viewController in
                    
                    self.mainNavigationController.pushViewController(
                        viewController,
                        animated: true
                    )
                    //            self.mainNavigationController.present(viewController, animated: true)
                }, completion: { _ in
                    self.mainNavigationController.dismiss(animated: true)
                    self.resettableBibleLanguageCoordinator.reset()
                    //            self.resettableSplashScreenCoordinator.reset()
                    
                }, context: .push(onto: self.mainNavigationController))
            }
        })
    }
    
    private func goToHamburger() {
        DDLogDebug("goToHamburger")
        self.swapInSideMenuFlow()
    }
    
    private func goToSettings() {
        DDLogDebug("goToSettings")
    }
    
    private func swapInMediaRouteFlow(mediaRoute: MediaRoute) {
        os_log("mediaRoute: %{public}@", log: OSLog.data, String(describing: mediaRoute))

        //        resettableMainCoordinator.value.bibleChannelUuid = bibleChannelUuid
        //
        //        resettableMainCoordinator.value.gospelChannelUuid = gospelChannelUuid
        //        resettableMainCoordinator.value.preachingChannelUuid = preachingChannelUuid
        //        resettableMainCoordinator.value.musicChannelUuid = musicChannelUuid
        resettableMediaRouteCoordinator.value.mediaRoute = mediaRoute
        resettableMediaRouteCoordinator.value.navigationController = self.mainNavigationController
        //        resettableMediaRouteCoordinator.value.navigationController = self.navi
        //        resettableMediaRouteCoordinator.value.doMediaRoute()
        
        resettableMediaRouteCoordinator.value.flow(with: { viewController in
            DDLogDebug("mediaroutecoordinator viewController: \(viewController)")
        }, completion: { [weak self] _ in
            
            }, context: .other)
    }

    private func swapInMediaUniversalLinkFlow(mediaUniversalLink: MediaUniversalLink) {
        os_log("mediaUniversalLink: %{public}@", log: OSLog.data, String(describing: mediaUniversalLink))

        //        resettableMainCoordinator.value.bibleChannelUuid = bibleChannelUuid
        //
        //        resettableMainCoordinator.value.gospelChannelUuid = gospelChannelUuid
        //        resettableMainCoordinator.value.preachingChannelUuid = preachingChannelUuid
        //        resettableMainCoordinator.value.musicChannelUuid = musicChannelUuid
        resettableMediaRouteCoordinator.value.mediaUniversalLink = mediaUniversalLink
        resettableMediaRouteCoordinator.value.navigationController = self.mainNavigationController
        //        resettableMediaRouteCoordinator.value.navigationController = self.navi
        //        resettableMediaRouteCoordinator.value.doMediaRoute()
        
        resettableMediaRouteCoordinator.value.flow(with: { viewController in
            DDLogDebug("mediaroutecoordinator viewController: \(viewController)")
        }, completion: { [weak self] _ in
            
            }, context: .other)
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown, .notReachable, .reachable(_):
                    os_log("mediaroutecoordinator %@", log: OSLog.data, String(describing: self.reachability.status.value))
                }
            }).disposed(by: bag)
    }
    private func swapInNoResourceFlow() {
        DDLogDebug("swapInNoResourceFlow")
        
        //        resettableNoResourceCoordinator.value.appFlowStatus = self.appFlowStatus
        //        resettableNoResourceCoordinator.value.serverStatus = self.serverStatus
        resettableNoResourceCoordinator.value.networkStatus = self.networkStatus.value
        resettableNoResourceCoordinator.value.flow(with: { [unowned self] noResourceViewController in
            //            self.rootViewController.plant(noResourceViewController, withAnimation: AppAnimations.fade)
            }, completion: { [unowned self] _ in
                //                    self.swapInMainFlow()
                self.resettableNoResourceCoordinator.reset()
            }, context: .other)
    }
    
}

// MARK: Event handling for the main flow.
extension MainCoordinator {
    private func handle(eventsFrom mainViewModel: PlaylistViewModel) {
        mainViewModel.drillInEvent.next { [unowned self] type in
            switch type {
                
            case .playlistItemType(let item, let mediaCategory):
                DDLogDebug("handle event: \(item)")
                self.goToPlaylist(item.uuid, mediaCategory)
            }
        }
    }
    
    private func handle(eventsFrom mainViewModel: BooksViewModel) {
        mainViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .bookType(let bookUuid):
                DDLogDebug(".defaultType: \(bookUuid)")
                self.goToBook(for: bookUuid)
            }
        }.disposed(by: bag)
        
        //        mainViewModel.nowPlayingDetailsEvent.next { [unowned self] in
        //            self.resettableDeviceNowPlayingCoordinator.value.flow(with: { viewController in
        //                self.mainNavigationController.present(viewController, animated: true)
        //            }, completion: { _ in
        //                self.mainNavigationController.dismiss(animated: true)
        //                self.resettableDeviceNowPlayingCoordinator.reset()
        //            }, context: .present)
        //        }.disposed(by: bag)
        
        //        mainViewModel.showControlCentreEvent.next { [unowned self] in
        //            // get current device from device manager and give it to the control center coordinator
        //            // if the current device changes we should alert then invalidate the control center flow
        //
        //            guard let device = self.deviceManager.currentDevice.value
        //                else {
        //                    self.mainNavigationController.showInfo(title: "No Device Selected", message: "Please select a device.")
        //                    return
        //            }
        //
        //            self.deviceContextBag = DisposeBag()
        //
        //            self.deviceManager.currentDevice.asObservable().next { currentDevice in
        //                guard let currentDevice = currentDevice,
        //                    currentDevice.identifier == device.identifier else {
        //                        self.mainNavigationController.showInfo(title: "Device Context Lost", message: "The current device has either been lost or changed.") {
        //                            self.mainNavigationController.dismiss(animated: true)
        //                            self.resettableControlCentreCoordinator.reset()
        //                        }
        //                        return
        //                }
        //            }.disposed(by: self.deviceContextBag)
        //
        //            self.resettableControlCentreCoordinator.value.device = device
        //
        //            self.resettableControlCentreCoordinator.value.flow(with: { viewController in
        //                viewController.transitioningDelegate = self
        //                self.mainNavigationController.present(viewController, animated: true)
        //            }, completion: { _ in
        //                self.mainNavigationController.dismiss(animated: true)
        //                self.resettableControlCentreCoordinator.reset()
        //            }, context: .present)
        //        }.disposed(by: bag)
    }
    
    private func handle(eventsFrom sideMenuViewModel: SideMenuViewModel) {
        sideMenuViewModel.drillInEvent.next { [unowned self] type in
            DispatchQueue.main.async {
                switch type {
                case .bible:
                    DDLogDebug(".bible")
                    self.dismiss()
                case .gospel:
                    DDLogDebug(".soulwinning")
                    if let channelUuid: String = self.gospelChannelUuid {
                        self.goToChannel(channelUuid: channelUuid)
                    } else {
                        DDLogError("⚠️ fatal error, need a soulwinning/Gospel Channel! Bailing!")
                        self.mainFlowCompletion(FlowCompletionType.error)
                    }
                case .preaching:
                    DDLogDebug(".preaching")
                    if let channelUuid: String = self.preachingChannelUuid {
                        self.goToChannel(channelUuid: channelUuid)
                    } else {
                        DDLogError("⚠️ fatal error, need a preaching Channel! Bailing!")
                        self.mainFlowCompletion(FlowCompletionType.error)
                    }
                case .music:
                    DDLogDebug(".music")
                    if let channelUuid: String = self.musicChannelUuid {
                        self.goToChannel(channelUuid: channelUuid)
                    } else {
                        DDLogError("⚠️ fatal error, need a music Channel! Bailing!")
                        self.mainFlowCompletion(FlowCompletionType.error)
                    }
                case .aboutUs:
                    DDLogDebug(".aboutUs")
                    self.goToExternalWebBrowser(url: NSURL(
                        string: "https://www.faithfulwordapp.com/")!
                        as URL)
                case .history:
                    DDLogDebug(".history")
                    self.goToHistoryFlow()
                case .setBibleLanguage:
                    DDLogDebug(".setBibleLanguage")
                    self.goToBibleLanguageFlow()
                    
                case .donate:
                    DDLogDebug(".donate")
                    self.goToExternalWebBrowser(url: NSURL(
                        string: "https://www.faithfulwordapp.com/donate/")!
                        as URL)
                case .privacyPolicy:
                    DDLogDebug(".privacyPolicy")
                    self.goToExternalWebBrowser(url: NSURL(
                        string: "https://www.faithfulwordapp.com/privacy-policy/")!
                        as URL)
                case .contactUs:
                    DDLogDebug(".contactUs")
                    self.goToMailComposer()
                }
            }
        }.disposed(by: bag)
    }
}

extension MainCoordinator {
    func dismiss() {
        self.mainNavigationController.dismiss(animated: true, completion: nil)
    }
    
    func handleMediaRouteEvents() {
        mediaRouteListenerBag = DisposeBag()
        mediaRouteHandler.mediaRouteEvent
            //            .filter { $0.host == "success" }
            .next { [weak self] mediaRoute in
                os_log("got media route event: %{public}@", log: OSLog.data, String(describing: mediaRoute))

                if let strongSelf = self {
                    strongSelf.swapInMediaRouteFlow(mediaRoute: mediaRoute)
                }
                
                //                guard let queryItems = deeplink.queryItems,
                //                    let musicServiceDeeplink = AddMusicServiceDeeplink(queryItems: queryItems) else {
                //                        self.navigationController?.dismiss(animated: true, completion: nil)
                //                        return
                //                }
                
                //                let addServiceProgress = self.uiFactory.makeAddServiceProgress(succeeded: musicServiceDeeplink.success,
                //                                                                               musicServiceName: musicServiceDescription.assets.name)
                //                self.navigationController?.presentedViewController?.present(addServiceProgress, animated: true, completion: {
                //                    //swiftlint:disable:next force_cast
                //                    self.handle(addServiceProgressViewModel: addServiceProgress.viewModel as! AddServiceProgressViewModel)
                //                })
        }.disposed(by: mediaRouteListenerBag)
    }
    
    func handleMediaUniversalLinkEvents() {
        mediaUniversalLinkListenerBag = DisposeBag()
        os_log("handleMediaUniversalLinkEvents mediaUniversalLinkListenerBag: %{public}@", log: OSLog.data, String(describing: mediaUniversalLinkListenerBag))

        mediaUniversalLinkHandler.mediaUniversalLinkEvent
//        mediaRouteHandler.mediaRouteEvent
            //            .filter { $0.host == "success" }
            .next { [weak self] mediaUniversalLink in
                os_log("got mediaUniversalLink event: %{public}@", log: OSLog.data, String(describing: mediaUniversalLink))

                if let strongSelf = self {
                    strongSelf.swapInMediaUniversalLinkFlow(mediaUniversalLink: mediaUniversalLink)
                }
                
                //                guard let queryItems = deeplink.queryItems,
                //                    let musicServiceDeeplink = AddMusicServiceDeeplink(queryItems: queryItems) else {
                //                        self.navigationController?.dismiss(animated: true, completion: nil)
                //                        return
                //                }
                
                //                let addServiceProgress = self.uiFactory.makeAddServiceProgress(succeeded: musicServiceDeeplink.success,
                //                                                                               musicServiceName: musicServiceDescription.assets.name)
                //                self.navigationController?.presentedViewController?.present(addServiceProgress, animated: true, completion: {
                //                    //swiftlint:disable:next force_cast
                //                    self.handle(addServiceProgressViewModel: addServiceProgress.viewModel as! AddServiceProgressViewModel)
                //                })
        }.disposed(by: mediaUniversalLinkListenerBag)
    }
}
