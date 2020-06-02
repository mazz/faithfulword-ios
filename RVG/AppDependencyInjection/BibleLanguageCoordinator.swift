import Foundation
import RxSwift
import os.log

internal final class BibleLanguageCoordinator  {
    // MARK: Dependencies

    internal let uiFactory: AppUIMaking
    private let resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>
    private let reachability: RxClassicReachable

    // MARK: Fields
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking,
                  resettableNoResourceCoordinator: Resettable<NoResourceCoordinator>,
                  reachability: RxClassicReachable
                  ) {
        self.uiFactory = uiFactory
        self.resettableNoResourceCoordinator = resettableNoResourceCoordinator
        self.reachability = reachability
        
        reactToReachability()
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown, .notReachable, .reachable(_):
                    os_log("BibleLanguageCoordinator %@", log: OSLog.data, String(describing: self.reachability.status.value))
                }
            }).disposed(by: bag)
    }
    
    private func swapInNoResourceFlow() {
        DDLogDebug("swapInNoResourceFlow")

//        resettableNoResourceCoordinator.value.appFlowStatus = self.appFlowStatus
//        resettableNoResourceCoordinator.value.serverStatus = self.serverStatus
        resettableNoResourceCoordinator.value.networkStatus = self.networkStatus.value
        resettableNoResourceCoordinator.value.flow(with: { [unowned self] noResourceViewController in
//            self.rootViewController.plant(noResourceViewController, withAnimation: AppAnimations.fade)
            }, completion: { [unowned self] _ in
                //                    self.swapInMainFlow()
                self.resettableNoResourceCoordinator.reset()
            }, context: .other)
    }
}

extension BibleLanguageCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        
//        switch self.networkStatus.value {
//            case .unknown, .notReachable:
//            self.swapInNoResourceFlow()
//        case .reachable(_):
            let bibleLanguageController = uiFactory.makeBibleLanguagePage()
            setup(bibleLanguageController)
//        }
        
    }
}
