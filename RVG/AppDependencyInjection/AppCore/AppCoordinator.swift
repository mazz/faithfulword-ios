import Foundation
import UIKit
import RxSwift
import L10n_swift
import Alamofire
import Loaf
import SwiftKeychainWrapper

/// Coordinator in charge of navigating between the two main states of the app.
/// Operates on the level of the rootViewController and switches between the
/// initialCoordinator, used in the unauthenticated state, and the mainCoordinator,
/// used in the authenticated state.
/// Lives for the entire lifetime of the app.

public enum AppFlowStatus {
    case none
    case login
    case loadOrg
    case loadChannels
    case main
}

public enum ServerConnectivityStatus {
    case none
    case connected
    case notConnected
}

internal class AppCoordinator {
    
    // MARK: Fields
    
    private var rootViewController: RootViewController!
    private var sideMenuViewController: SideMenuViewController!
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    var appFlowStatus: AppFlowStatus = .login
    var serverStatus: ServerConnectivityStatus = .none
    
    private let bag = DisposeBag()
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
    //    private let resettableInitialCoordinator: Resettable<InitialCoordinator>
    private let resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>
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
        resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>,
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
        self.resettableNoResourceCoordinator = resettableNoResourceCoordinator
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
        
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil) { notification in
            // we need to cleanup the downloads if they were interrupted
            // - if their progress is < 1.0 but their state is .inProgress,
            //   remark it as .interrupted
            
            self.downloadService.resetIncompleteDownloads(toState: .interrupted)
            
            // HWI download manager has a proprietary dir where it saves
            // files to. delete it and its contents at startup
            self.downloadService.deleteHwiDownloadDirectory()
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AppCoordinator.handleApplicationWillTerminate(notification:)), name: AppDelegate.applicationWillTerminate, object: nil)

        reactToReachability()
        
        resettableNoResourceCoordinator.value.tryAgainTapped
            .asObservable()
            .next { [weak self] flowStatus in
                
                if let strongSelf = self,
                    let rootViewController = strongSelf.rootViewController,
                    let serverStatus = self?.serverStatus {
                    
                    var toastMessage: String = NSLocalizedString("Connecting …", comment: "").l10n()
                    switch serverStatus {
                    case .none, .notConnected, .connected:
                        toastMessage = NSLocalizedString("Connecting …", comment: "").l10n()
                        Loaf(toastMessage,
                             state: .info,
                             location: .bottom,
                             presentingDirection: .vertical,
                             dismissingDirection: .vertical,
                             sender: rootViewController)
                            .show()
                    }
                    
                    switch flowStatus {
                    case .none:
                        DDLogDebug("none")
                    case .login:
                        DDLogDebug("login")
                    case .loadOrg:
                        strongSelf.loadDefaultOrg()
                    case .loadChannels:
                        DDLogDebug("loadChannels")
                        strongSelf.productService.persistedDefaultOrg()
                            .subscribe(onSuccess: { org in
                                if let org = org {
                                    strongSelf.loadChannels(for: org.uuid)
                                } else {
                                    DDLogDebug("no persisted org found")
                                }
                            }, onError: { error in
                                DDLogDebug("error fetching persisted org: \(error)")
                            }).disposed(by: strongSelf.bag)
                    case .main:
                        DDLogDebug("main")
                        strongSelf.productService.persistedDefaultOrg()
                            .subscribe(onSuccess: { org in
                                if let org = org {
                                    strongSelf.loadChannels(for: org.uuid)
                                } else {
                                    DDLogDebug("no persisted org found")
                                }
                            }, onError: { error in
                                DDLogDebug("error fetching persisted org: \(error)")
                            }).disposed(by: strongSelf.bag)
                    }
                }
            }.disposed(by: self.bag)

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
//                self.languageService.fetchUserLanguage()
//                    .subscribe(onSuccess: { [weak self] userLanguage in
                
                        if let rootViewController = self.rootViewController {
//                            DDLogDebug("self.languageService.userLanguage.value: \(self?.languageService.userLanguage.value) == \(userLanguage)")
//                            L10n.shared.language = (userLanguage == "") ? "en" : userLanguage
                            
                            if authState == .unauthenticated {
                                // load default org if unauthenticated
                                Loaf.dismiss(sender: rootViewController)
                                
                                switch self.networkStatus.value {
                                case .notReachable, .reachable(_), .unknown:
                                    self.appFlowStatus = .loadOrg
                                    self.loadDefaultOrg()
//                                case .none:
//                                    self.appFlowStatus = .loadOrg
//                                    self.loadDefaultOrg()
                                }
                                
                            } else if authState == .authenticated || authState == .emailUnconfirmed {
                                DDLogDebug("authState: \(authState)")
                                Loaf.dismiss(sender: rootViewController)
                                
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
                        }
                        
                        
                        
                        
//                    }, onError: { error in
//                        DDLogDebug("fetch user language failed with error: \(error.localizedDescription)")
//                    }).disposed(by: self.bag)
            })
            .disposed(by: bag)
    }
    
    private func loadDefaultOrg() {
        
        var loadedOrgs: [Org] = []
        
        let persistedOrgs: Single<[Org]>  = productService.persistedDefaultOrgs()

        persistedOrgs.subscribe(onSuccess: { [weak self] persisted in
            if let strongSelf = self,
                let rootViewController = strongSelf.rootViewController {
                switch strongSelf.networkStatus.value {
                case .unknown, .notReachable:
                    if persisted.count == 0 {
                        DDLogDebug("⚠️ No internet and no Org found, can't do anything")
                        strongSelf.serverStatus = .notConnected
                        strongSelf.swapInNoResourceFlow()
                    } else {
                        loadedOrgs = persisted
                        if let org: Org = loadedOrgs.first {
                            strongSelf.serverStatus = .notConnected
                            strongSelf.appFlowStatus = .loadChannels
                            strongSelf.loadChannels(for: org.uuid)
                            
                            strongSelf.loginToOrg(org)
                        }
                    }
                case .reachable(_):
                    Loaf(NSLocalizedString("Connecting …", comment: "").l10n(),
                         state: .info,
                         location: .bottom,
                         presentingDirection: .vertical,
                         dismissingDirection: .vertical,
                         sender: rootViewController)
                        .show()
                    
                    if persisted.count == 0 {
                        strongSelf.productService.fetchDefaultOrgs(offset: 1, limit: 100).subscribe(onSuccess: { [weak self] fetchedOrgs in
                            loadedOrgs = fetchedOrgs
                            DDLogDebug("loadedOrgs: \(loadedOrgs)")
                            if loadedOrgs.count == 0 {
                                DDLogDebug("⚠️ No internet and no Org found, can't do anything")
                                strongSelf.swapInNoResourceFlow()
                            } else {
                                if let org: Org = loadedOrgs.first {
                                    strongSelf.serverStatus = .connected
                                    strongSelf.appFlowStatus = .loadChannels
                                    strongSelf.loadChannels(for: org.uuid)
                                    
                                    strongSelf.loginToOrg(org)
                                }
                            }
                        }) { error in
                            // typical error here: MoyaError|AFError Error Domain=NSURLErrorDomain Code=-1001 "The request timed out."
                            DDLogDebug("error: \(error)")
                            DDLogDebug("⚠️ Internet but no Org found, can't do anything")
                            strongSelf.serverStatus = .notConnected
                            strongSelf.swapInNoResourceFlow()
                            }.disposed(by: strongSelf.bag)
                    } else {
                        loadedOrgs = persisted
                        if let org: Org = loadedOrgs.first {
                            strongSelf.serverStatus = .connected
                            strongSelf.appFlowStatus = .loadChannels
                            strongSelf.loadChannels(for: org.uuid)
                            
                            strongSelf.loginToOrg(org)
                        }
                    }
                }
                
            }
            
            
            
        }) { error in
            DDLogDebug("⚠️ error getting persistedDefaultOrgs: \(error)")
            self.swapInNoResourceFlow()
        }.disposed(by: self.bag)
    }
    
    private func loginToOrg(_ org: Org)  {
        self.accountService.fetchAppUser()
            .subscribe(onSuccess: { [weak self] userAppUser in
                if let strongSelf = self {
                    if let user: UserAppUser = userAppUser,
                        let faithfulWordAppIdx: String = KeychainWrapper.standard.string(forKey: "app.faithfulword.userpassword") {
                        // found a stored UserAppUser, so start login flow
                        
                        // for v1.3 we will not be actually logging-in
                        // instead below, make a fake user, even a fake password
                        // the fake UserAppUser will not have a corresponding UserLoginUser
                        // so do nothing here

//                        strongSelf.accountService.startLoginFlow(email: user.email, password: faithfulWordAppIdx)
//                            .subscribe(onSuccess: { userLoginResponse in
//                                DDLogDebug("userLoginResponse \(userLoginResponse)")
//                            }, onError: { error in
//                                DDLogDebug("⚠️ login error! \(error)")
//                                Loaf.dismiss(sender: strongSelf.rootViewController)
//                            }).disposed(by: strongSelf.bag)
                        
                    } else {
                        // did not find a stored UserAppUser, so start signup flow
                        
                        // for v1.3 we will not be actually logging-in
                        // instead, make a fake user, even a fake password
                        // the fake UserAppUser will not have a corresponding UserLoginUser
                        
                        
                        let hashSource: String = NSUUID().uuidString
                        let faithfulWordAppIdx: String = String("fw\(hashSource.sha512Hex.prefix(30))")
                        let name: String = faithfulWordAppIdx.filter { "abcdefghijklmnopqrstuvwxyz".contains($0) }
                        if KeychainWrapper.standard.set(faithfulWordAppIdx, forKey: "app.faithfulword.userpassword") {
                            
                        }
                        /** uncomment hopefully someday
                        if KeychainWrapper.standard.set(faithfulWordAppIdx, forKey: "app.faithfulword.userpassword") {
                            strongSelf.accountService.startSignupFlow(user: ["username" : faithfulWordAppIdx,
                                                                             "name": name,
                                                                             "email": "\(faithfulWordAppIdx)@faithfulword.app",
                                "password": faithfulWordAppIdx,
                                "passwordRepeat": faithfulWordAppIdx,
                                "locale": "en",
                                "org_id": org.orgId])
                                .subscribe(onSuccess: { signupResponse in
                                    DDLogDebug("signupResponse \(signupResponse)")
                                }, onError: { error in
                                    DDLogDebug("⚠️ login error! \(error)")
                                }).disposed(by: strongSelf.bag)
                        }
                        */
                        strongSelf.accountService.replaceAppUser(user: UserAppUser(userId: 0,
                                                                              uuid: NSUUID().uuidString,
                                                                              orgId: org.org_id,
                                                                              name: name,
                                                                              email: "\(faithfulWordAppIdx)@faithfulword.app",
                            session: "fake.\(NSUUID().uuidString)",
                            pushNotifications: false,
                            language: L10n.shared.language,
                            userLoginUserUuid: nil))
                            .asObservable()
                            .subscribeAndDispose(by: strongSelf.bag)
                    }
                }
                }, onError: { error in
                    
            }).disposed(by: self.bag)
    }
    
    private func loadChannels(for orgUuid: String) {
        var loadedChannels: [Channel] = []

        
        let persistedChannels: Single<[Channel]>  = productService.persistedChannels(for: orgUuid)
        
        persistedChannels.subscribe(onSuccess: { [weak self] persisted in
            //            if persisted.count == 0 {
            
            if let strongSelf = self {
                switch strongSelf.networkStatus.value {
                case .unknown, .notReachable:
                    if persisted.count == 0 {
                        DDLogError("⚠️ no channels and no network! should probably make the user aware somehow")
                        strongSelf.serverStatus = .notConnected
                        strongSelf.appFlowStatus = .main
                        strongSelf.swapInNoResourceFlow()
                    } else {
                        loadedChannels = persisted
                        strongSelf.swapInMainFlow(channels: loadedChannels)
                    }
                case .reachable(_):
                    if persisted.count == 0 {
                        strongSelf.productService.fetchChannels(for: orgUuid, offset: 1, limit: 100).subscribe(onSuccess: { fetchedChannels in
                            //                        DDLogDebug("chans: \(chans)")
                            loadedChannels = fetchedChannels
                            strongSelf.swapInMainFlow(channels: loadedChannels)
                            DDLogDebug("loadedChannels: \(loadedChannels)")
                            if loadedChannels.count == 0 {
                                DDLogDebug("⚠️ Internet but no channels found, can't do anything")
                                strongSelf.serverStatus = .notConnected
                                strongSelf.appFlowStatus = .main
                                strongSelf.swapInNoResourceFlow()
                            }
                        }) { error in
                            DDLogDebug("error: \(error)")
                            strongSelf.serverStatus = .notConnected
                            strongSelf.appFlowStatus = .main
                            strongSelf.swapInNoResourceFlow()
                            }.disposed(by: strongSelf.bag)
                    } else {
                        loadedChannels = persisted
                        strongSelf.serverStatus = .notConnected
                        strongSelf.appFlowStatus = .main
                        strongSelf.swapInMainFlow(channels: loadedChannels)
                    }
                }
                
            }
        }) { error in
            DDLogDebug("⚠️ error getting persistedChannels: \(error)")
            self.swapInNoResourceFlow()
        }.disposed(by: self.bag)
        
    }

    /// Puts the no network/resources flow on top of the rootViewController
    /// this should be shown only when neither there is auth/orgs/channels nor network at the same time
    private func swapInNoResourceFlow() {
        DDLogDebug("swapInNoResourceFlow")
        
        
        resettableNoResourceCoordinator.value.appFlowStatus = self.appFlowStatus
        resettableNoResourceCoordinator.value.serverStatus = self.serverStatus
        resettableNoResourceCoordinator.value.networkStatus = self.networkStatus.value
        resettableNoResourceCoordinator.value.flow(with: { [unowned self] noResourceViewController in
            self.rootViewController.plant(noResourceViewController, withAnimation: AppAnimations.fade)
            }, completion: { [unowned self] _ in
                //                    self.swapInMainFlow()
                self.resettableNoResourceCoordinator.reset()
            }, context: .other)
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
                
                
//                self.accountService.startSignupFlow(user: ["user": "" ])
                    
                // bootstrap login/fetching of session HERE because we have no login UI
//                self.accountService.startLoginFlow(email: "joseph@faithfulword.app", password: "password")
//                    .subscribe(onSuccess: { [unowned self] userLoginResponse in
//                        let user: UserAppUser = UserAppUser(userId: userLoginResponse.user.id,
//                                              uuid: NSUUID().uuidString,
//                                              orgId: userLoginResponse.user.org_id,
//                                              name: userLoginResponse.user.name ?? "unknown",
//                                              email: userLoginResponse.user.email,
//                                              session: userLoginResponse.token,
//                                              pushNotifications: false,
//                                              language: "en",
//                                              userLoginUserUuid: userLoginResponse.user.uuid)
//
//
//                    }, onError: { error in
//                        DDLogDebug("⚠️ login error! \(error)")
//                        Loaf.dismiss(sender: self.rootViewController)
//
//                        Loaf(error.localizedDescription,
//                             state: .info,
//                             location: .bottom,
//                             presentingDirection: .vertical,
//                             dismissingDirection: .vertical,
//                             sender: self.rootViewController)
//                            .show()
//
//                    }).disposed(by: self.bag)
                
                
//{
//    "user": {
//        "username": "jeebin",
//        "name": "Jedediah Solomon",
//        "email": "grabbler@test.test",
//        "password": "Open1sesa",
//        "passwordRepeat": "Open1sesa",
//        "locale": "en",
//        "org_id": 1
//    }
//}
//                self.accountService.startSignupFlow(user: ["user" : ["username" : "jeebin",
//                                                                     "name": "Jedediah Solomon",
//                                                                     "email": "grabbler@test.test",
//                                                                     "password": "asdfasdf1",
//                                                                     "passwordRepeat": "asdfasdf1",
//                                                                     "locale": "en",
//                                                                     "org_id": 1]])

//                self.accountService.fetchAppUser()
//                    .subscribe(onSuccess: { [weak self] userAppUser in
//                        if let strongSelf = self {
//                            if let user: UserAppUser = userAppUser,
//                                let faithfulWordAppIdx: String = KeychainWrapper.standard.string(forKey: "app.faithfulword.userpassword") {
//                                // found a stored UserAppUser, so start login flow
//                                strongSelf.accountService.startLoginFlow(email: user.email, password: faithfulWordAppIdx)
//                                    .subscribe(onSuccess: { userLoginResponse in
//                                        DDLogDebug("userLoginResponse \(userLoginResponse)")
//                                    }, onError: { error in
//                                        DDLogDebug("⚠️ login error! \(error)")
//                                        Loaf.dismiss(sender: strongSelf.rootViewController)
////                                        Loaf(error.localizedDescription,
////                                             state: .info,
////                                             location: .bottom,
////                                             presentingDirection: .vertical,
////                                             dismissingDirection: .vertical,
////                                             sender: strongSelf.rootViewController)
////                                            .show()
//
//                                    }).disposed(by: strongSelf.bag)
//
//                            } else {
//                                // did not find a stored UserAppUser, so start signup flow
//
//                                let hashSource: String = NSUUID().uuidString
//                                let faithfulWordAppIdx: String = String("fw\(hashSource.sha512Hex.prefix(30))")
//                                let name: String = faithfulWordAppIdx.filter { "abcdefghijklmnopqrstuvwxyz".contains($0) }
//
//                                if KeychainWrapper.standard.set(faithfulWordAppIdx, forKey: "app.faithfulword.userpassword") {
//                                    strongSelf.accountService.startSignupFlow(user: ["username" : faithfulWordAppIdx,
//                                                                                     "name": name,
//                                                                                     "email": "\(faithfulWordAppIdx)@faithfulword.app",
//                                                                                     "password": faithfulWordAppIdx,
//                                                                                     "passwordRepeat": faithfulWordAppIdx,
//                                                                                     "locale": "en",
//                                                                                     "org_id": 1])
//                                        .subscribe(onSuccess: { signupResponse in
//                                            DDLogDebug("signupResponse \(signupResponse)")
//                                        }, onError: { error in
//                                            DDLogDebug("⚠️ login error! \(error)")
//                                        }).disposed(by: strongSelf.bag)
//                                }
//
//
//                            }
//                        }
//                        }, onError: { error in
//
//                    }).disposed(by: self.bag)
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
                case .unknown, .notReachable, .reachable(_):
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
