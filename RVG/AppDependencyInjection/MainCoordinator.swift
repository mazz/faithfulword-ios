import UIKit
import RxSwift
import SafariServices

internal enum MainRevealState {
    case closed
    case open
}

/// Coordinator in charge of all navigation in authenticated state.
/// Handles navigation between the main and device selection flows.
internal final class MainCoordinator: NSObject {
    // MARK: Fields

    private let menuTransitionManager = MenuTransitionManager()
    private var mainNavigationController: UINavigationController!
    private var sideMenuController: SideMenuController?

    private let bag = DisposeBag()
    private var deviceContextBag = DisposeBag()
    private var mainFlowCompletion: FlowCompletion!

    // hamburger
    private var mainViewRevealed: MainRevealState = .closed
    private var originalMenuFrame: CGRect!

    // MARK: Dependencies

    private let appUIMaking: AppUIMaking
//    private let resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>
    private let resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
    private let resettableSideMenuCoordinator: Resettable<SideMenuCoordinator>

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
        resettableSideMenuCoordinator: Resettable<SideMenuCoordinator>

//                  resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>,
//                  resettableDeviceSelectionCoordinator: Resettable<DeviceSelectionCoordinator>,
//                  resettableSectionalNavigatorCoordinator: Resettable<SectionalNavigatorCoordinator>,
//                  resettableControlCentreCoordinator: Resettable<ControlCentreCoordinator>,
//                  deviceManager: DeviceManaging
        ) {
        self.appUIMaking = appUIMaking
        self.resettableMediaListingCoordinator = resettableMediaListingCoordinator
        self.resettableSideMenuCoordinator = resettableSideMenuCoordinator

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
        let mainViewController = appUIMaking.makeMain()
        attachRootMenuAction(to: mainViewController)
        attachSettingAction(to: mainViewController)
        
        mainNavigationController = UINavigationController(rootViewController: mainViewController)
        
        // keep original state of hamburger so we know what frame to toggle back to
        originalMenuFrame = self.mainNavigationController.view.frame
        
        handle(eventsFrom: mainViewController.viewModel)
        setup(mainNavigationController)
        
//        resettableSectionalNavigatorCoordinator.value.flow(with: { sectionalNavigator in
//            mainViewController.plant(sectionalNavigator)
//        }, completion: { [unowned self] _ in
//            self.resettableSectionalNavigatorCoordinator.reset()
//        }, context: .other)
        mainFlowCompletion = completion
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

    private func goToBook(for bookUuid: String) {
        // do not use a new flow, because Chapters is part of the Book flow AFAICT
//        self.resettableSplashScreenCoordinator.value.flow(with: { viewController in
        
        self.resettableMediaListingCoordinator.value.playlistId = bookUuid
        self.resettableMediaListingCoordinator.value.mediaType = .audioChapter
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
        resettableSideMenuCoordinator.value.flow(with: { [unowned self] sideMenuViewController in
            sideMenuViewController.transitioningDelegate = menuTransitionManager
            menuTransitionManager.delegate = self
            
            if let controller = sideMenuViewController as? SideMenuController {
                self.sideMenuController = controller
//                self.sideMenuController = sideMenuViewController as! SideMenuController
                handle(eventsFrom: (self.sideMenuController?.viewModel)!)
            }

            self.mainNavigationController.present(sideMenuViewController, animated: true)
//            self.rootViewController.embed(sideMenuViewController, in: self.rootViewController.view)//(sideMenuViewController, withAnimation: AppAnimations.fade)
            //            self.sideMenuViewController = sideMenuViewController as! SideMenuController
            }, completion: { [unowned self] _ in
                //                            self.swapInMainFlow()
                
                //                self.startHandlingAuthEvents()
                //                self.accountService.start()
                //
                //                // bootstrap login/fetching of session HERE because we have no login UI
                //                self.accountService.startLoginFlow()
                //                    .asObservable()
                //                    .subscribeAndDispose(by: self.bag)
                self.mainNavigationController.dismiss(animated: true)
                self.resettableSideMenuCoordinator.reset()
            }, context: .present)
    }

    private func goToHamburger() {
        print("goToHamburger")
        self.swapInSideMenuFlow()
//        tappedHamburger.onNext(mainViewRevealed)
        
        
//        let mainViewController: MainViewController = self.mainNavigationController.viewControllers[0] as! MainViewController
//        self.mainNavigationController.viewControllers[0].transitioningDelegate = self
        

        /*
        let mainNavigationView: UIView = self.mainNavigationController.view
        let mainView: UIView = self.mainNavigationController.viewControllers[0].view

        var targetRect: CGRect!
        let openX: CGFloat = mainView.frame.size.width * 0.85
        
        switch mainViewRevealed {
        case .closed:
            targetRect = CGRect(x: openX,
                                y: originalMenuFrame.origin.y,
                                width: originalMenuFrame.size.width,
                                height: originalMenuFrame.size.height)
        case .open:
            targetRect = CGRect(x: 0.0,
                                y: originalMenuFrame.origin.y,
                                width: originalMenuFrame.size.width,
                                height: originalMenuFrame.size.height)
        }
        let hamburgerAnimation: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
            mainNavigationView.frame = targetRect
        }
        
        hamburgerAnimation.addCompletion { [unowned self] position in
            switch self.mainViewRevealed {
            case .closed:
                mainView.isUserInteractionEnabled = false
                self.mainViewRevealed = .open
            case .open:
                mainView.isUserInteractionEnabled = true
                self.mainViewRevealed = .closed
            }
        }
        hamburgerAnimation.startAnimation()

        */

//        self.resettableDeviceSelectionCoordinator.value.flow(with: { viewController in
//            self.mainNavigationController.present(viewController, animated: true)
//        }, completion: { _ in
//            self.mainNavigationController.dismiss(animated: true)
//            self.resettableDeviceSelectionCoordinator.reset()
//        }, context: .present)
    }

    private func goToSettings() {
        print("goToSettings")
//        resettableSettingsCoordinator.value.flow(with: { [unowned self] settingsFlowViewController in
//            self.mainNavigationController.present(settingsFlowViewController, animated: true)
//        }, completion: { [unowned self] _ in
//            self.mainNavigationController.dismiss(animated: true)
//            self.resettableSettingsCoordinator.reset()
//        }, context: .present)
    }
}

// MARK: Event handling for the main flow.
extension MainCoordinator {
    
    private func handle(eventsFrom mainViewModel: MainViewModel) {
        mainViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .bookType(let bookUuid):
                print(".defaultType: \(bookUuid)")
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
                    print(".bible")
                    self.dismiss()
                case .soulwinning:
                    print(".soulwinning")
                case .music:
                    print(".music")
                case .aboutUs:
                    print(".aboutUs")
                    self.dismissAndGoToInlineWebBrowser(url: NSURL(
                        string:"http://allscripturebaptist.com/")!
                        as URL)
                case .share:
                    print(".share")
                case .setBibleLanguage:
                    print(".setBibleLanguage")
                case .donate:
                    print(".donate")
                    self.dismissAndGoToExternalWebBrowser(url: NSURL(
                        string:"http://allscripturebaptist.com/donate/")!
                        as URL)
                case .privacyPolicy:
                    print(".privacyPolicy")
                    self.dismissAndGoToInlineWebBrowser(url: NSURL(
                        string:"http://allscripturebaptist.com/privacy-policy/")!
                        as URL)
                case .contactUs:
                    print(".contactUs")
                    self.dismissAndGoToMailComposer()
                }
            }
            }.disposed(by: bag)
    }
}

extension MainCoordinator {
    private func dismissAndGoToInlineWebBrowser(url: URL) {
        self.mainNavigationController.dismiss(animated: true, completion: {
            let svc = self.appUIMaking.makeInlineWebBrowser(url: url)
            self.mainNavigationController.pushViewController(svc,
                                                             animated: true)
        })
    }

    func dismissAndGoToExternalWebBrowser(url: URL) {
        self.mainNavigationController.dismiss(animated: true) {
            UIApplication.shared.open(url, options: [:],
                        completionHandler: nil)
        }
    }

    func dismissAndGoToMailComposer() {
        self.mainNavigationController.dismiss(animated: true, completion: {
            if let mailComposer = self.appUIMaking.makeMailComposer() {
                self.mainNavigationController.pushViewController(mailComposer,
                                                                 animated: true)
            } else {
                let okAlert = self.appUIMaking.makeOkAlert(
                    title: NSLocalizedString(
                        "Mail services are not available", comment: "").l10n(),
                    message: "")
                self.mainNavigationController.pushViewController(okAlert,
                                                                 animated: true)
            }
        })
    }
}

extension MainCoordinator: MenuTransitionManagerDelegate {
    func dismiss() {
        self.mainNavigationController.dismiss(animated: true, completion: nil)
    }
}
