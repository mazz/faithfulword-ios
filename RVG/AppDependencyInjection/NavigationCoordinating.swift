import UIKit
import RxSwift

/// Instructions for setting up the first view controller in a coordinator's flow.
public typealias FlowSetup = (UIViewController) -> Void

/// Type for differentiating between whether a flow finished as intended or was cancelled
public enum FlowCompletionType {
    case finished
    case cancelled
}

/// Instructions for tearing down after a coordinator completes its flow.
public typealias FlowCompletion = (FlowCompletionType) -> Void

/// Various contexts in which a coordinator can start its flow.
///
/// - present: Presenting a modal.
/// - push: Pushing onto a navigation stack.
/// - other: Neither presenting nor pushing. Might be embedding or setting the window's root.
public enum FlowContext {
    case present
    case push(onto: UINavigationController)
    case other
}

/// Basic enforcement of what a cooridnator should do
/// i.e. start & end a navigation flow
public protocol NavigationCoordinating {
    func flow(with setup: FlowSetup,
              completion: @escaping FlowCompletion,
              context: FlowContext)
}

extension NavigationCoordinating {
    public func addCustomBackButton(to viewController: UIViewController, with action: @escaping () -> Void) -> Disposable {
        let backButton = UIBarButtonItem.back()
        viewController.navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = backButton
        return backButton.rx.tap.asObservable().next { action() }
    }
    
    public func addCloseButton(to viewController: UIViewController, with action: @escaping () -> Void) -> Disposable {
        let close = UIBarButtonItem.close()
        viewController.navigationItem.leftBarButtonItem = close
        return close.rx.tap.asObservable().next { action() }
    }
}
