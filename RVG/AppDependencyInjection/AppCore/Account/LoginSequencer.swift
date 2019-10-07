import Foundation
import RxSwift

public protocol LoginSequencing {
    var sessionToken: Observable<String?> { get } // a JWT
    var loginUser: Observable<UserLoginUser?> { get }

    func login(email: String, password: String) -> Single<UserLoginResponse>
    func signup(user: [String: AnyHashable]) -> Single<UserSignupResponse>

//    func startRegistrationFlow(over viewController: UIViewController) -> Single<Void>
//    func startUpdateFlow(over viewController: UIViewController)
    func logout()
}

public final class LoginSequencer {
    
    // MARK: Fields
    
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
//    private let didyaManaging: DidyaManaging
    private let dataService: AccountDataServicing
    
    public init(
//        didyaManaging: DidyaManaging,
        dataService: AccountDataServicing) {
//        self.didyaManaging = didyaManaging
        self.dataService = dataService
    }
}

extension LoginSequencer: LoginSequencing {
    public var sessionToken: Observable<String?> {
        return dataService.token.do(onNext: { session in
            DDLogDebug("got session: \(String(describing: session))")
        })
    }

    public var loginUser: Observable<UserLoginUser?> {
        return dataService.loginUser.do(onNext: { user in
            DDLogDebug("got loginUser: \(String(describing: user))")
        })
    }

    // TODO: just fetches a fake session for now
    public func login(email: String, password: String) -> Single<UserLoginResponse> {
//        let userLoginResponse: Single<UserLoginResponse> = self.dataService.loginUser(email: email, password: password)
        return self.dataService.loginUser(email: email, password: password)
//            .flatMap({ loginResponse -> Single<UserLoginUser> in
//                Single.just(loginResponse.user)
//            })

//        userLoginResponse.flatMap { userLoginResponse -> Single<UserLoginUser> in
//            return userLoginResponse.user
//        }
        
//        return self.fetchSession()
    }
//
//    public func startRegistrationFlow(over viewController: UIViewController) -> Single<Void> {
//        return didyaManaging.startRegistrationFlow(over: viewController)
//            .flatMap { [unowned self] in self.fetchSession(for: $0) }
//    }
//    
//    public func startUpdateFlow(over viewController: UIViewController) {
//        didyaManaging.startUpdateFlow(over: viewController)
//    }
    
    public func signup(user: [String: AnyHashable]) -> Single<UserSignupResponse> {
        return self.dataService.signupUser(user: user)
    }
    
    public func logout() {
        // currently we do not delete a user on logout because that would remove all
        // data associated with that user
        // TODO: eventually we would want a Session table in the database
        // which a user would have a foreign key dependency on
        // the Session row in the Session table associated with the logging-out user would
        // be then deleted, effectively logging the user out
        
//        dataService.deleteSession().subscribe().disposed(by: bag)
    }
}
