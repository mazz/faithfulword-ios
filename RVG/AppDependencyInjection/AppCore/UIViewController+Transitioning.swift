import Foundation
import UIKit
import RxSwift
import RxCocoa

public extension UIViewController {
    
    /// Emits event when popped off a navigation controller's stack.
    /// Coordinator's may be interested in this if they need to complete their flow.
    var popped: Observable<Void> {
        return rx.methodInvoked(#selector(UIViewController.viewWillDisappear))
            .filter { [unowned self] _ in
                guard let navigationController = self.navigationController else { return false }
                return !navigationController.viewControllers.contains(self)
            }
            .map { _ in () }
    }
    
    /// Embeds a view-controller in the receiver with animation.
    /// This method is kept private because callers should use `safeEmbed`
    ///
    /// - Parameters:
    ///   - viewController: The view-controller to be embeded.
    ///   - containerView: The container view to embed the view-controller's view into.
    ///   - animation: The animation codeblock, defaults to nil
    public func embed(_ viewController: UIViewController,
                      in containerView: UIView,
                      withAnimation animation: AppAnimations.Animatable? = nil) {
        addChildViewController(viewController)
        viewController.view.frame = containerView.bounds
        containerView.addSubview(viewController.view)
        // Animation closure is called if animation argument is passed
        if let animation = animation {
            animation(viewController, {
                viewController.didMove(toParentViewController: self)
            })
        } else {
            viewController.didMove(toParentViewController: self)
        }
    }
    
    /// Safely executes block only when view has been loaded.
    /// Will defer invocation to post-`viewDidLoad` if view not loaded.
    ///
    /// - Parameter execute: The closure to be executed when view available.
    public func viewSafe(_ execute: @escaping () -> Void) {
        if isViewLoaded {
            execute()
        } else {
            _ = rx.methodInvoked(#selector(UIViewController.viewDidLoad))
                .takeUntil(rx.deallocated)
                .take(1)
                .subscribe({ _ in
                    execute()
                })
        }
    }
    
    /// Removes a view-controller in the the receiver.
    ///
    /// - Parameter viewController: The view-controller to be removed.
    public func remove(_ viewController: UIViewController) {
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
    
    /// Replaces an embedded view-controller with new view-controller and animation.
    ///
    /// - Parameters:
    ///   - originalViewController: The view-controller to remove.
    ///   - destinationViewController: The view-controller to add.
    ///   - containerView: The container view to embed the view-controller's view into.
    ///   - animation: The animation codeblock, defaults to nil.
    public func replace(_ originalViewController: UIViewController?,
                        with destinationViewController: UIViewController,
                        in containerView: UIView,
                        withAnimation animation: AppAnimations.Animatable? = nil) {
        if let originalViewController = originalViewController {
            remove(originalViewController)
        }
        embed(destinationViewController, in: containerView, withAnimation: animation)
    }
}
