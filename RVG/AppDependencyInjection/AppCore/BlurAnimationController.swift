import UIKit

fileprivate let duration: TimeInterval = 0.2 // swiftlint:disable:this private_over_fileprivate
fileprivate let visualEffectViewTag = 777  // hack! // swiftlint:disable:this private_over_fileprivate

/// Animation controller which cross fades modal view controllers into view with a dark blur background
public class PresentBlurAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        toView.alpha = 0
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.effect = nil
        blurView.frame = containerView.bounds
        blurView.tag = visualEffectViewTag
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            toView.alpha = 1
            toView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
            blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
        
        containerView.addSubview(toView)
        toView.addSubview(blurView)
        toView.sendSubviewToBack(blurView)
    }
}

/// Animation controller which cross fades modal view controllers with a blurred background out of view
public class DismissBlurAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: .from)!
        let blurView = fromView.viewWithTag(visualEffectViewTag) as? UIVisualEffectView
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration/2, delay: 0, options: .curveLinear, animations: {
            fromView.alpha = 0
        })
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            blurView?.effect = nil
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
