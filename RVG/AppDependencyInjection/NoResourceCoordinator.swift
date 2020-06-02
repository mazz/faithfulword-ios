//
//  NoResourceCoordinator.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-29.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import UIKit
import RxSwift

/// Coordinator in charge of all navigation through the splash screen.

enum NoResourceViewSiblingStatus {
    case embedded
    case pushed
}

internal final class NoResourceCoordinator {
    
    // MARK: Fields
    private var noResourceViewController: NoResourceViewController!
    public var noResourceNavigationController: UINavigationController?
    public var noResourceRootViewController: RootViewController?
    
    public var viewControllerSiblingStatus: NoResourceViewSiblingStatus?
    
    public var appFlowStatus: AppFlowStatus?
    public var networkStatus: ClassicReachability.NetworkStatus?
    public var serverStatus: ServerConnectivityStatus?

    public var tryAgainTapped: PublishSubject<Void> = PublishSubject()
    private var noResourceFlowCompletion: FlowCompletion!
    
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

// MARK: <NavigationCoordinating>
extension NoResourceCoordinator: NavigationCoordinating {
    
    /// Creates and sets up the splashScreenViewController and sets it as the root of
    /// the splashScreenNavigationController, triggers animation
    
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
//        if let appFlowStatus: AppFlowStatus = self.appFlowStatus,
//            if let networkStatus: ClassicReachability.NetworkStatus = self.networkStatus
//            let serverStatus: ServerConnectivityStatus = self.serverStatus
//        {
        self.noResourceViewController = uiFactory.makeNoResourcePage()
//        }
        //        noResourceNavigationController = UINavigationController(rootViewController: noResourceViewController)
        
        // first check if nav controller is not nil
        // otherwise plant in the root view controller
        
        //        if let navigationViewController = noResourceNavigationController {
        //
        //        } else {
        //            if let rootViewController = noResourceRootViewController {
        //
        //            } else {
        //                DDLogError("⚠️ navigation logic error, either nav or root should be non-nil")
        //            }
        //        }
        
        
        
        //        noResource = NoResourceViewController.create()
        handle(eventsFrom: self.noResourceViewController.viewModel)
        setup(self.noResourceViewController)
        //        noResourceViewController.plant(noResource)
        // Animate pulsing and gose in box
        //        noResource.animateText(AnimationConstants.splashScreenTransition ) { [weak self] in
        //            self?.noResource.remove()
        //            completion(.finished)
        //        }
    }
    
    internal func tryAppFlowAgain() {
        
        if self.viewControllerSiblingStatus == .embedded {
            if let viewController: NoResourceViewController = self.noResourceViewController {
                viewController.remove(viewController)
            }
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tryAgainTapped.onNext(())
//        }
    }
}

extension NoResourceCoordinator {
    private func handle(eventsFrom viewModel: NoResourceViewModel) {
        viewModel.tapTryAgainEvent.next { appFlowStatus in
            self.tryAppFlowAgain()
        }
    }
    
}
