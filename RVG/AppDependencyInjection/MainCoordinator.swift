import UIKit
import RxSwift

/// Coordinator in charge of all navigation in authenticated state.
/// Handles navigation between the main and device selection flows.
internal final class MainCoordinator: NSObject {
    
    // MARK: Fields
    
    private var mainNavigationController: UINavigationController!
    private let bag = DisposeBag()
    private var deviceContextBag = DisposeBag()
    private var mainFlowCompletion: FlowCompletion!
    
    // MARK: Dependencies
    
    private let appUIMaking: AppUIMaking
//    private let resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>
    private let resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
    
//    private let resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
    
//    private let resettableDeviceSelectionCoordinator: Resettable<DeviceSelectionCoordinator>
//    private let resettableSectionalNavigatorCoordinator: Resettable<SectionalNavigatorCoordinator>
//    private let resettableControlCentreCoordinator: Resettable<ControlCentreCoordinator>
    private let presentBlurAnimationController: UIViewControllerAnimatedTransitioning = PresentBlurAnimationController()
    private let dismissBlurAnimationController: UIViewControllerAnimatedTransitioning = DismissBlurAnimationController()
//    private let deviceManager: DeviceManaging

    internal init(appUIMaking: AppUIMaking,
//                  resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
                  resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
//                  resettableDeviceNowPlayingCoordinator: Resettable<DeviceNowPlayingCoordinator>,
//                  resettableDeviceSelectionCoordinator: Resettable<DeviceSelectionCoordinator>,
//                  resettableSectionalNavigatorCoordinator: Resettable<SectionalNavigatorCoordinator>,
//                  resettableControlCentreCoordinator: Resettable<ControlCentreCoordinator>,
//                  deviceManager: DeviceManaging
        ) {
        self.appUIMaking = appUIMaking
        self.resettableMediaListingCoordinator = resettableMediaListingCoordinator
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
            self.goToDeviceSelection()
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

    private func goToBook(for bookId: String) {
        // do not use a new flow, because Chapters is part of the Book flow AFAICT
//        self.resettableSplashScreenCoordinator.value.flow(with: { viewController in
        
        self.resettableMediaListingCoordinator.value.playlistId = bookId
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

        
//        self.MainCoordinator.pushViewController(
//            uiFactory.makeTrackSelection(),
//            animated: true
//        )
    }

    private func goToDeviceSelection() {
        print("goToDeviceSelection")
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
            case .bookType(let bookId):
                print(".defaultType: \(bookId)")
                self.goToBook(for: bookId)
            default:
                break
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
}

//extension MainCoordinator {
//    private func goToTracks() {
//        // do not use a new flow, because Chapters is part of the Book flow AFAICT
//        self.MainCoordinator.pushViewController(
//            uiFactory.makeTrackSelection(),
//            animated: true
//        )
//    }
//}

extension MainCoordinator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentBlurAnimationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissBlurAnimationController
    }
}
