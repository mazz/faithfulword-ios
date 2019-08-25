import Foundation
import UIKit
import RxSwift

public enum AuthStatus {
    case initialState
    case authenticated
    case unauthenticated
    case emailUnconfirmed
//    case accountInfoRetrieved
}

public enum AccountServiceError: Error {
    case noSession
}

public protocol AccountServicing {
    // Current authentication state
    var authState: Observable<AuthStatus> { get }
    // Current user
    var currentUser: UserAppUser? { get }
    // Current user's music service accounts
//    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }
    
    func start()
    func logout()
    
    func startLoginFlow(email: String, password: String) -> Single<UserLoginResponse>
//    func startLoginFlow(over viewController: UIViewController) -> Single<Void>
//    func startRegistrationFlow(over viewController: UIViewController) -> Single<Void>
//    func startUpdateFlow(over viewController: UIViewController)
    
//    func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]>
}

/// Manages all account related things
public final class AccountService {
    
    // MARK: Fields
    
    public var authState: Observable<AuthStatus> {
        return authStateBehaviorSubject.asObservable().filter { $0 != .initialState }.distinctUntilChanged()
    }
    private let authStateBehaviorSubject = BehaviorSubject<AuthStatus>(value: .initialState)
    
    public var currentUser: UserAppUser?
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private var loginSequencer: LoginSequencing
    private let dataService: AccountDataServicing
    
    public init(loginSequencer: LoginSequencing, dataService: AccountDataServicing) {
        self.loginSequencer = loginSequencer
        self.dataService = dataService
    }
    
    // MARK: Helpers
    
//    private func fetchAccountInfo() {
//        dataService.fetchAccountInfo().subscribe(onSuccess: { [unowned self] accountInfo in
//            DDLogDebug("Cached Login Flow - Retrieved Passport Account Info: \(accountInfo)")
//            self.currentUser?.accountInfo = accountInfo
//            self.authStateBehaviorSubject.onNext(.accountInfoRetrieved)
//        }).disposed(by: bag)
//    }
}

extension AccountService: AccountServicing {
//    public var musicServiceAccounts: Observable<[MusicServiceAccount]> { return dataService.musicServiceAccounts }
    
    public func start() {
        
        Observable.combineLatest(loginSequencer.sessionToken, loginSequencer.loginUser)
            .subscribe(onNext: { sessionToken, loginUser in
                if let sessionToken = sessionToken,
                    let loginUser = loginUser {
                    let uuid: String = NSUUID().uuidString
                    let appUser: UserAppUser = UserAppUser(userId: loginUser.id,
                                                   uuid: uuid,
                                                   orgId: loginUser.org_id,
                                                   name: loginUser.name,
                                                   email: loginUser.email,
                                                   session: sessionToken,
                                                   pushNotifications: false,
                                                   language: "en",
                                                   userLoginUserUuid: loginUser.uuid)
                    
                    self.currentUser = appUser

                    self.dataService.appendPersistedLoginUser(user: loginUser)
                        .asObservable()
                        .subscribe(onNext: { userLoginUser in
                            
                            self.dataService.addUser(user: appUser)
                                .asObservable()
                                .subscribeAndDispose(by: self.bag)
                            
                        })
                        .disposed(by: self.bag)
                    
                    
                    
                    if loginUser.email_confirmed == false {
                        self.authStateBehaviorSubject.onNext(.emailUnconfirmed)
                    } else {
                        self.authStateBehaviorSubject.onNext(.authenticated)
                    }
                } else {
                    self.currentUser = nil
                    self.authStateBehaviorSubject.onNext(.unauthenticated)
                }
            })
            .disposed(by: self.bag)
        
//        loginSequencer.sessionToken.subscribe(onNext: { [unowned self] session in
//            if let session = session {
////                self.currentUser = ApplicationUser(userSession: session)
//                self.authStateBehaviorSubject.onNext(.authenticated)
////                self.fetchAccountInfo()
//            } else {
//                self.currentUser = nil
//                self.authStateBehaviorSubject.onNext(.unauthenticated)
//            }
//        }).disposed(by: bag)
    }
    
    public func logout() {
        loginSequencer.logout()
    }

    public func startLoginFlow(email: String, password: String) -> Single<UserLoginResponse> {
        return loginSequencer.login(email: email, password: password)
    }

//    public func startLoginFlow(over viewController: UIViewController) -> Single<Void> {
//        return loginSequencer.startLoginFlow(over: viewController)
//    }
//
//    public func startRegistrationFlow(over viewController: UIViewController) -> Single<Void> {
//        return loginSequencer.startRegistrationFlow(over: viewController)
//    }
//
//    public func startUpdateFlow(over viewController: UIViewController) {
//        loginSequencer.startUpdateFlow(over: viewController)
//    }
    
//    public func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]> {
//        return dataService.fetchMusicServiceAccounts()
//    }
}
