//
//  MenuTransitionManager.swift
//  SlideMenu
//
//  Created by Simon Ng on 19/10/2015.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import UIKit

@objc protocol MenuTransitionManagerDelegate {
    func dismiss()
}

class MenuTransitionManager: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    let duration = 0.5
    var isPresenting = false
    
    var snapshot:UIView? {
        didSet {
            if let delegate = delegate {
                let tapGestureRecognizer = UITapGestureRecognizer(target: delegate, action: #selector(MenuTransitionManagerDelegate.dismiss))
                snapshot?.addGestureRecognizer(tapGestureRecognizer)
                snapshot?.layer.shadowRadius = 10.0
                snapshot?.layer.shadowOpacity = 0.7

            }
        }
    }
    
    var delegate:MenuTransitionManagerDelegate?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get reference to our fromView, toView and the container view
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        // Set up the transform we'll use in the animation
        let containerView = transitionContext.containerView
        
        
        let moveDown = CGAffineTransform(translationX: 0, y: containerView.frame.height - 150)
        let moveUp = CGAffineTransform(translationX: 0, y: -50)
        
        let moveRight = CGAffineTransform(translationX: containerView.frame.width - 75, y: 0)
        let moveLeft = CGAffineTransform(translationX: 0, y: 0)

        // Add both views to the container view
        if isPresenting {
//            toView.transform = moveUp
            toView.transform = moveLeft
            snapshot = fromView.snapshotView(afterScreenUpdates: true)
            containerView.addSubview(toView)
            containerView.addSubview(snapshot!)
        }
        
        // Perform the animation
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
            
            if self.isPresenting {
//                self.snapshot?.transform = moveDown
                self.snapshot?.transform = moveRight
                toView.transform = CGAffineTransform.identity
            } else {
                self.snapshot?.transform = CGAffineTransform.identity
//                fromView.transform = moveUp
                fromView.transform = moveLeft
            }
            
            }, completion: { finished in
                
                transitionContext.completeTransition(true)

                if !self.isPresenting {
                    self.snapshot?.removeFromSuperview()
                }
        })
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        isPresenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        isPresenting = false
        return self
    }

}
