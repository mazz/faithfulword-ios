import Foundation
import UIKit
import RxSwift
//import BoseMobileModels
//import BoseMobileCore
//import BoseMobilePresentation
//import BoseMobileUI
//import BoseMobileUtilities

/// Coordinator in charge of navigating between the two main states of the app.
/// Operates on the level of the rootViewController and switches between the
/// initialCoordinator, used in the unauthenticated state, and the mainCoordinator,
/// used in the authenticated state.
/// Lives for the entire lifetime of the app.

internal class AppCoordinator {
    
    // MARK: Fields
    
    private var rootViewController: RootViewController!
    private let bag = DisposeBag()
    
    
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
//    private let resettableInitialCoordinator: Resettable<InitialCoordinator>
    private let resettableMainCoordinator: Resettable<MainCoordinator>
    private let resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
//    private let resettableAccountSetupCoordinator: Resettable<AccountSetupCoordinator>
//    private let accountService: AccountServicing
//    private let productService: ProductServicing
    
    internal init(uiFactory: AppUIMaking,
//                  resettableInitialCoordinator: Resettable<InitialCoordinator>
                  resettableMainCoordinator: Resettable<MainCoordinator>,
                  resettableSplashScreenCoordinator: Resettable<SplashScreenCoordinator>
//                  resettableAccountSetupCoordinator: Resettable<AccountSetupCoordinator>,
//                  accountService: AccountServicing,
//                  productService: ProductServicing
        ) {
        self.uiFactory = uiFactory
//        self.resettableInitialCoordinator = resettableInitialCoordinator
        self.resettableMainCoordinator = resettableMainCoordinator
        self.resettableSplashScreenCoordinator = resettableSplashScreenCoordinator
//        self.resettableAccountSetupCoordinator = resettableAccountSetupCoordinator
//        self.accountService = accountService
//        self.productService = productService
    }
}

// MARK: <NavigationCoordinating>
extension AppCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        rootViewController = uiFactory.makeRoot()
        setup(rootViewController)
        // Load splash screen animations, proceed to other flows when completed
        swapInSplashScreenFlow()
    }
    
    private func startHandlingAuthEvents() {
        
        // while we do not require auth,
        // just check for user books for now
        self.checkUserBooks()

        // On Logout, go back to the Initial flow
//        accountService.authState
//            // Event only fire on main thread
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [unowned self] authState in
//                if authState == .authenticated {
//                    self.checkUserBooks()
//                } else if authState == .unauthenticated {
//                    self.swapInInitialFlow()
//                }
//            })
//            .disposed(by: bag)
    }
    
    private func checkUserBooks() {

        // TODO: fetch books from bible service here
        // just swap in main flow for now
        self.swapInMainFlow()

//        self.productService.fetchProducts().subscribe(onSuccess: { [unowned self] in
//            if self.productService.userProducts.value.count > 0 {
//                self.swapInMainFlow()
//            } else {
//                self.swapInAccountSetupFlow()
//            }
//        }, onError: { [unowned self] error in
//            BoseLog.error("Check user products failed with error: \(error.localizedDescription)")
//            self.swapInMainFlow()
//        }).disposed(by: self.bag)
    }
    
    /// Puts the initial flow (unauthenticated state) on top of the rootViewController,
    /// and sets up the initial flow to be replaced by the main flow when complete.
    private func swapInInitialFlow() {
//        resettableInitialCoordinator.value.flow(with: { [unowned self] initialFlowViewController in
//            self.rootViewController.plant(initialFlowViewController, withAnimation: BoseAnimations.fade)
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
            self.startHandlingAuthEvents()
//            self.accountService.start()
        }, context: .other)
    }
    
    private func swapInAccountSetupFlow() {
//        resettableAccountSetupCoordinator.value.flow(with: { [unowned self] accountSetupNavigationController in
//            self.rootViewController.plant(accountSetupNavigationController)
//        }, completion: { [unowned self] _ in
//            self.swapInMainFlow()
//        }, context: .other)
    }
}
