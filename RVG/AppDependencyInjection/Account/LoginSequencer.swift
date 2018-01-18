import Foundation
import RxSwift

public protocol LoginSequencing {
    var session: Observable<String?> { get } // a session is a simple String for now
    
    func startLoginFlow() -> Single<Void>
//    func startRegistrationFlow(over viewController: UIViewController) -> Single<Void>
//    func startUpdateFlow(over viewController: UIViewController)
    func logout()
}

public final class LoginSequencer {
    
    // MARK: Fields
    
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
//    private let gigyaManaging: GigyaManaging
    private let dataService: AccountDataServicing
    
    public init(
//        gigyaManaging: GigyaManaging,
        dataService: AccountDataServicing) {
//        self.gigyaManaging = gigyaManaging
        self.dataService = dataService
    }
    
    // MARK: Helpers
    
    // TODO: should eventually pass a JWT in here
    private func fetchSession() -> Single<Void> {
        return dataService.fetchSession().map { _ in () }
    }    
}

extension LoginSequencer: LoginSequencing {
    public var session: Observable<String?> {
        return dataService.session.do(onNext: { session in // currently just a simple string
            print("got session: \(String(describing: session))")
        })
    }
    
    // TODO: just fetches a fake session for now
    public func startLoginFlow() -> Single<Void> {
        return self.fetchSession()
    }
//
//    public func startRegistrationFlow(over viewController: UIViewController) -> Single<Void> {
//        return gigyaManaging.startRegistrationFlow(over: viewController)
//            .flatMap { [unowned self] in self.fetchSession(for: $0) }
//    }
//    
//    public func startUpdateFlow(over viewController: UIViewController) {
//        gigyaManaging.startUpdateFlow(over: viewController)
//    }
    
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
