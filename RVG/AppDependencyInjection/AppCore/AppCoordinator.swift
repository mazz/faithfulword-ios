import Foundation
import UIKit
import RxSwift
import L10n_swift
import Alamofire

/// Coordinator in charge of navigating between the two main states of the app.
/// Operates on the level of the rootViewController and switches between the
/// initialCoordinator, used in the unauthenticated state, and the mainCoordinator,
/// used in the authenticated state.
/// Lives for the entire lifetime of the app.

internal class AppCoordinator {
    
    // MARK: Fields
    
    private var rootViewController: RootViewController!
    private var sideMenuViewController: SideMenuViewController!
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    private let bag = DisposeBag()
    
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
    //    private let resettableInitialCoordinator: Resettable<InitialCoordinator>
    private let resettableMainCoordinator: Resettable<MainCoordinator>
    private let resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
    //    private let resettableAccountSetupCoordinator: Resettable<AccountSetupCoordinator>
    private let accountService: AccountServicing
    private let productService: ProductServicing
    private let languageService: LanguageServicing
    private let assetPlaybackService: AssetPlaybackServicing
    private let reachability: RxClassicReachable
    
    internal init(uiFactory: AppUIMaking,
                  //                  resettableInitialCoordinator: Resettable<InitialCoordinator>
        resettableMainCoordinator: Resettable<MainCoordinator>,
        resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>,
        //                  resettableAccountSetupCoordinator: Resettable<AccountSetupCoordinator>,
        accountService: AccountServicing,
        productService: ProductServicing,
        languageService: LanguageServicing,
        assetPlaybackService: AssetPlaybackServicing,
        reachability: RxClassicReachable
        ) {
        self.uiFactory = uiFactory
        //        self.resettableInitialCoordinator = resettableInitialCoordinator
        self.resettableMainCoordinator = resettableMainCoordinator
        self.resettableSplashScreenCoordinator = resettableSplashScreenCoordinator
        //        self.resettableAccountSetupCoordinator = resettableAccountSetupCoordinator
        self.accountService = accountService
        self.productService = productService
        self.languageService = languageService
        self.assetPlaybackService = assetPlaybackService
        self.reachability = reachability
        
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { notification in            
            if let taskId: UIBackgroundTaskIdentifier = self.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(taskId)
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { notification in
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "main", expirationHandler: nil)
        }

        reactToReachability()
    }
}

// MARK: <NavigationCoordinating>
extension AppCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        //        rootViewController = uiFactory.makeRoot()
        //        setup(rootViewController)
        
        rootViewController = uiFactory.makeRoot()
        setup(rootViewController)
        
        //        sideMenuViewController = uiFactory.makeSideMenu()
        //        self.rootViewController.embed(sideMenuViewController, in: self.rootViewController.view)
        
        // Load splash screen animations, proceed to other flows when completed
        swapInSplashScreenFlow()
    }
    
    private func startHandlingAssetPlaybackEvents() {
        //        assetPlaybackService.start()
    }
    
    private func startHandlingAuthEvents() {
        
        // while we do not require auth,
        // just check for user books for now
        //        self.checkUserBooks()
        
        // On Logout, go back to the Initial flow
        accountService.authState
            // Event only fire on main thread
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] authState in
                if authState == .authenticated {
                    DDLogDebug("authenticated")
                    
                    // we must fetch and set the user language before we do
                    // anything, really
                    self.languageService.fetchUserLanguage().subscribe(onSuccess: { userLanguage in
                        DDLogDebug("self.languageService.userLanguage.value: \(self.languageService.userLanguage.value) == \(userLanguage)")
                        L10n.shared.language = userLanguage
                        
                        //            self.swapInMainFlow()
                        
                        switch self.networkStatus.value {
                        case .notReachable:
                            self.loadDefaultOrg()

                        case .reachable(_):
                            self.loadDefaultOrg()

                        case .unknown:
                            self.loadDefaultOrg()
                        }
                    }, onError: { error in
                        DDLogDebug("fetch user language failed with error: \(error.localizedDescription)")
                    }).disposed(by: self.bag)

                    
                    
                } else if authState == .unauthenticated {
                    self.swapInInitialFlow()
                    DDLogDebug("unauthenticated")
                }
            })
            .disposed(by: bag)
    }
    
    private func loadDefaultOrg() {
        
        var orgs: [Org] = []

        self.productService.fetchDefaultOrgs(offset: 1, limit: 100).subscribe(onSuccess: { [unowned self] defaultOrgs in
            DDLogDebug("default orgs: \(defaultOrgs)")
            orgs = self.productService.defaultOrgs.value
            self.swapInMainFlow()
        }) { error in
            DDLogDebug("error: \(error)")
        }.disposed(by: self.bag)

        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("orgs: \(orgs)")
            
        case .reachable(_):
            DDLogDebug("orgs: \(orgs)")
//            self.productService.fetchDefaultOrgs(offset: 1, limit: 100).subscribe(onSuccess: { [unowned self]  defaultOrgs in
//                DDLogDebug("default orgs: \(defaultOrgs)")
//                orgs = self.productService.defaultOrgs.value
//                self.swapInMainFlow()
//            })
//                .disposed(by: self.bag)

        case .unknown:
            DDLogDebug("orgs: \(orgs)")
//            self.productService.fetchDefaultOrgs(offset: 1, limit: 100).subscribe(onSuccess: { [unowned self]  defaultOrgs in
//                DDLogDebug("default orgs: \(defaultOrgs)")
//                orgs = self.productService.defaultOrgs.value
//                self.swapInMainFlow()
//            })
//                .disposed(by: self.bag)
        }
        
        self.swapInMainFlow()

    }
    
    /// Puts the initial flow (unauthenticated state) on top of the rootViewController,
    /// and sets up the initial flow to be replaced by the main flow when complete.
    private func swapInInitialFlow() {
        DDLogDebug("swapInInitialFlow")
        //        resettableInitialCoordinator.value.flow(with: { [unowned self] initialFlowViewController in
        //            self.rootViewController.plant(initialFlowViewController, withAnimation: GoseAnimations.fade)
        //        }, completion: { [unowned self] _ in
        //            self.swapInMainFlow()
        //            self.resettableInitialCoordinator.reset()
        //        }, context: .other)
    }
    
    /// Puts the main flow (logged in state) on top of the rootViewController.
    private func swapInMainFlow() {
        resettableMainCoordinator.value.flow(with: { [unowned self] mainFlowViewController in
            self.rootViewController.plant(mainFlowViewController, withAnimation: AppAnimations.fade)
            }, completion: { [unowned self] _ in
                self.swapInInitialFlow()
                self.resettableMainCoordinator.reset()
            }, context: .other)
    }
    
    /// Puts the splash screen flow on top of the rootViewController, and animates the
    /// splash screen sequence. Authorization handling is called when complete.
    private func swapInSplashScreenFlow() {
        resettableSplashScreenCoordinator.value.flow(with: { [unowned self] splashScreenFlowViewController in
            self.rootViewController.plant(splashScreenFlowViewController)
            }, completion: { [unowned self] _ in
                self.startHandlingAssetPlaybackEvents()
                self.startHandlingAuthEvents()
                self.accountService.start()
                
                // bootstrap login/fetching of session HERE because we have no login UI
                self.accountService.startLoginFlow()
                    .asObservable()
                    .subscribeAndDispose(by: self.bag)
                
            }, context: .other)
    }
    
    private func swapInAccountSetupFlow() {
        DDLogDebug("swapInAccountSetupFlow")
        //        resettableAccountSetupCoordinator.value.flow(with: { [unowned self] accountSetupNavigationController in
        //            self.rootViewController.plant(accountSetupNavigationController)
        //        }, completion: { [unowned self] _ in
        //            self.swapInMainFlow()
        //        }, context: .other)
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown:
                    DDLogDebug("AppCoordinator \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("AppCoordinator \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("AppCoordinator \(self.reachability.status.value)")
                }
            }).disposed(by: bag)
    }
}
