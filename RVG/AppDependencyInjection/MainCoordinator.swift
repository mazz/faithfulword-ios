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
    
    private var sideMenuController: SideMenuViewController?
    internal var mainNavigationController: UINavigationController!
    internal var gospelChannelUuid: String?
    internal var preachingChannelUuid: String?
    internal var musicChannelUuid: String?
    internal var bibleChannelUuid: String?
    
    private let bag = DisposeBag()
    private var mediaRouteListenerBag = DisposeBag()
    private let mediaRouteHandler: MediaRouteHandling
    
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
    
    private let productService: ProductServicing
    
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
        mediaRouteHandler: MediaRouteHandling,
        productService: ProductServicing
        
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
        self.mediaRouteHandler = mediaRouteHandler
        
        self.productService = productService
        
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
}
