import Foundation
import UIKit
import RxSwift

public enum AuthStatus {
    case initialState
    case authenticated
    case unauthenticated
//    case accountInfoRetrieved
}

public enum AccountServiceError: Error {
    case noSession
}

public protocol AccountServicing {
    // Current authentication state
    var authState: Observable<AuthStatus> { get }
    // Current user
    var currentUser: ApplicationUser? { get }
    // Current user's music service accounts
//    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }
    
    func start()
    func logout()
    
    func startLoginFlow() -> Single<Void>
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
    
    public var currentUser: ApplicationUser?
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
//            print("Cached Login Flow - Retrieved Passport Account Info: \(accountInfo)")
//            self.currentUser?.accountInfo = accountInfo
//            self.authStateBehaviorSubject.onNext(.accountInfoRetrieved)
//        }).disposed(by: bag)
//    }
}

extension AccountService: AccountServicing {
//    public var musicServiceAccounts: Observable<[MusicServiceAccount]> { return dataService.musicServiceAccounts }
    
    public func start() {
        loginSequencer.session.subscribe(onNext: { [unowned self] session in
            if let session = session {
                self.currentUser = ApplicationUser(userSession: session)
                self.authStateBehaviorSubject.onNext(.authenticated)
//                self.fetchAccountInfo()
            } else {
                self.currentUser = nil
                self.authStateBehaviorSubject.onNext(.unauthenticated)
            }
        }).disposed(by: bag)
    }
    
    public func logout() {
        loginSequencer.logout()
    }

    public func startLoginFlow() -> Single<Void> {
        return loginSequencer.startLoginFlow()
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
