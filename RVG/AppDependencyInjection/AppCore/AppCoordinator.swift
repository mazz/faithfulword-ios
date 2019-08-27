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
    private let downloadService: DownloadServicing
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
        downloadService: DownloadServicing,
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
        self.downloadService = downloadService
        self.reachability = reachability
        
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { notification in            
            if let taskId: UIBackgroundTaskIdentifier = self.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(taskId)
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { notification in
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "main", expirationHandler: nil)
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AppCoordinator.handleApplicationWillTerminate(notification:)), name: AppDelegate.applicationWillTerminate, object: nil)

        
//        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { notification in
//
//            DDLogDebug("try and update state of any possible downloads now, downloadService: \(self.downloadService) notification: \(notification)")
//            self.downloadService.cancelAllDownloads()
//            sleep(5)
//        }

        reactToReachability()
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AppDelegate.applicationWillTerminate, object: nil)
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
                DDLogDebug("authState: \(authState)")

                // we must fetch and set the user language before we do
                // anything, really
                self.languageService.fetchUserLanguage()
                    .subscribe(onSuccess: { userLanguage in
                        DDLogDebug("self.languageService.userLanguage.value: \(self.languageService.userLanguage.value) == \(userLanguage)")
                        L10n.shared.language = (userLanguage == "") ? "en" : userLanguage

                        if authState == .unauthenticated {
                            // load default org if unauthenticated
                            
                            switch self.networkStatus.value {
                            case .notReachable:
                                self.loadDefaultOrg()
                                
                            case .reachable(_):
                                self.loadDefaultOrg()
                                
                            case .unknown:
                                self.loadDefaultOrg()
                            }

                        } else if authState == .authenticated || authState == .emailUnconfirmed {
                            DDLogDebug("authState: \(authState)")
                            
                            // TODO:
                            // unload currently loaded org and then
                            // load unique org that is associated with UserAppUser
                            // if authenticated or emailUnconfirmed
                            
//                            switch self.networkStatus.value {
//                            case .notReachable:
//                                self.loadDefaultOrg()
//
//                            case .reachable(_):
//                                self.loadDefaultOrg()
//
//                            case .unknown:
//                                self.loadDefaultOrg()
//                            }
                        }
                    }, onError: { error in
                        DDLogDebug("fetch user language failed with error: \(error.localizedDescription)")
                    }).disposed(by: self.bag)
            })
            .disposed(by: bag)
    }
    
    private func loadDefaultOrg() {
        
        var loadedOrgs: [Org] = []
        
        let persistedOrgs: Single<[Org]>  = productService.persistedDefaultOrgs()

        persistedOrgs.subscribe(onSuccess: { persisted in
            switch self.networkStatus.value {
            case .unknown:
                if persisted.count == 0 {
                    DDLogDebug("⚠️ No internet and no Org found, can't do anything")
                    self.swapInNoResourceFlow()
                } else {
                    loadedOrgs = persisted
                    if let uuid: String = loadedOrgs.first?.uuid {
                        self.loadChannels(for: uuid)
                    }
                }
            case .notReachable:
                if persisted.count == 0 {
                    DDLogDebug("⚠️ No internet and no Org found, can't do anything")
                    self.swapInNoResourceFlow()
                } else {
                    loadedOrgs = persisted
                    if let uuid: String = loadedOrgs.first?.uuid {
                        self.loadChannels(for: uuid)
                    }
                }
            case .reachable(_):
                if persisted.count == 0 {
                    self.productService.fetchDefaultOrgs(offset: 1, limit: 100).subscribe(onSuccess: { [unowned self] fetchedOrgs in
                        loadedOrgs = fetchedOrgs
                        DDLogDebug("loadedOrgs: \(loadedOrgs)")
                        if loadedOrgs.count == 0 {
                            DDLogDebug("⚠️ No internet and no Org found, can't do anything")
                            self.swapInNoResourceFlow()
                        } else {
                            if let uuid: String = loadedOrgs.first?.uuid {
                                self.loadChannels(for: uuid)
                            }
                        }
                    }) { error in
                        DDLogDebug("error: \(error)")
                        }.disposed(by: self.bag)
                } else {
                    loadedOrgs = persisted
                    if let uuid: String = loadedOrgs.first?.uuid {
                        self.loadChannels(for: uuid)
                    }
                }
            }
        }) { error in
            DDLogDebug("⚠️ error getting persistedDefaultOrgs: \(error)")
            self.swapInNoResourceFlow()
        }
    }
    
    private func loadChannels(for orgUuid: String) {
        var loadedChannels: [Channel] = []

        
        let persistedChannels: Single<[Channel]>  = productService.persistedChannels(for: orgUuid)
        
        persistedChannels.subscribe(onSuccess: { persisted in
            //            if persisted.count == 0 {
            switch self.networkStatus.value {
            case .unknown:
                if persisted.count == 0 {
                    DDLogError("⚠️ no channels and no network! should probably make the user aware somehow")
                    self.swapInNoResourceFlow()
                } else {
                    loadedChannels = persisted
                    self.swapInMainFlow(channels: loadedChannels)
                }
            case .notReachable:
                if persisted.count == 0 {
                    DDLogError("⚠️ no channels and no network! should probably make the user aware somehow")
                    self.swapInNoResourceFlow()
                } else {
                    loadedChannels = persisted
                    self.swapInMainFlow(channels: loadedChannels)
                }
            case .reachable(_):
                if persisted.count == 0 {
                    self.productService.fetchChannels(for: orgUuid, offset: 1, limit: 100).subscribe(onSuccess: { [unowned self] fetchedChannels in
                        //                        DDLogDebug("chans: \(chans)")
                        loadedChannels = fetchedChannels
                        self.swapInMainFlow(channels: loadedChannels)
                        DDLogDebug("loadedChannels: \(loadedChannels)")
                        if loadedChannels.count == 0 {
                            DDLogDebug("⚠️ Internet but no channels found, can't do anything")
                            self.swapInNoResourceFlow()
                        }
                    }) { error in
                        DDLogDebug("error: \(error)")
                        }.disposed(by: self.bag)
                } else {
                    loadedChannels = persisted
                    self.swapInMainFlow(channels: loadedChannels)
                }
            }
        }) { error in
            DDLogDebug("⚠️ error getting persistedChannels: \(error)")
            self.swapInNoResourceFlow()
        }
        
    }

    /// Puts the no network/resources flow on top of the rootViewController
    /// this should be shown only when neither there is auth/orgs/channels nor network at the same time
    private func swapInNoResourceFlow() {
        DDLogDebug("swapInNoResourceFlow")
        //        resettableInitialCoordinator.value.flow(with: { [unowned self] initialFlowViewController in
        //            self.rootViewController.plant(initialFlowViewController, withAnimation: GoseAnimations.fade)
        //        }, completion: { [unowned self] _ in
        //            self.swapInMainFlow()
        //            self.resettableInitialCoordinator.reset()
        //        }, context: .other)
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
    private func swapInMainFlow(channels: [Channel]) {
        if let bibleChannelUuid: String = channels.first(where: { $0.basename == "Bible" })?.uuid,
            let gospelChannelUuid: String = channels.first(where: { $0.basename == "Gospel" })?.uuid,
            let preachingChannelUuid: String = channels.first(where: { $0.basename == "Preaching" })?.uuid,
            let musicChannelUuid: String = channels.first(where: { $0.basename == "Music" })?.uuid {
            DDLogDebug("bibleChannelUuid: \(bibleChannelUuid)")
            resettableMainCoordinator.value.bibleChannelUuid = bibleChannelUuid
            
            resettableMainCoordinator.value.gospelChannelUuid = gospelChannelUuid
            resettableMainCoordinator.value.preachingChannelUuid = preachingChannelUuid
            resettableMainCoordinator.value.musicChannelUuid = musicChannelUuid
            
            resettableMainCoordinator.value.flow(with: { [unowned self] mainFlowViewController in
                self.rootViewController.plant(mainFlowViewController, withAnimation: AppAnimations.fade)
                }, completion: { [unowned self] _ in
                    self.swapInInitialFlow()
                    self.resettableMainCoordinator.reset()
                }, context: .other)
        } else {
            DDLogError("⚠️ fatal error, need a Bible Channel! Bailing!")
            self.swapInNoResourceFlow()
        }

        
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
                
                // create a default user once and once-only
                // because we don't have a login UI or a
                // way to add a new user
//                let userUuid: String = NSUUID().uuidString
//                
//                let user: UserAppUser = UserAppUser(userId: 0,
//                                      uuid: userUuid,
//                                      name: userUuid,
//                                      email: String(describing: "\(userUuid)@\(userUuid)"),
//                                      session: userUuid,
//                                      pushNotifications: false,
//                                      language: "en")
                
                
                // bootstrap login/fetching of session HERE because we have no login UI
                self.accountService.startLoginFlow(email: "joseph@faithfulword.app", password: "password")
                    .subscribe(onSuccess: { [unowned self] userLoginResponse in
                        let user: UserAppUser = UserAppUser(userId: userLoginResponse.user.id,
                                              uuid: NSUUID().uuidString,
                                              orgId: userLoginResponse.user.org_id,
                                              name: userLoginResponse.user.name ?? "unknown",
                                              email: userLoginResponse.user.email,
                                              session: userLoginResponse.token,
                                              pushNotifications: false,
                                              language: "en",
                                              userLoginUserUuid: userLoginResponse.user.uuid)
                        
                        
                    }, onError: { error in
                        DDLogDebug("⚠️ login error! \(error)")
                    })
                .disposed(by: self.bag)
//                    .asObservable()
                
                    
//                    .subscribeAndDispose(by: self.bag)
                
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
    
    @objc func handleApplicationWillTerminate(notification: Notification) {
        if self.downloadService.inProgressDownloads().count > 0 {
            self.downloadService.cancelAllDownloads()            
        }
    }
}
