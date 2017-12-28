import Foundation

public struct AppAnimations {
    
    // Animation constants
    static let fadeTime = 0.4
    
    // Type definition for Animatable
    // Params: viewController for animation, and completion block to be executed after animation
    public typealias Animatable = (_ viewController: UIViewController, _ completion: () -> Void) -> Void
    
    // Fade animation -- animates alpha of view controller from 0.0 to 1.0 over period of time
    public static func fade(_ viewController: UIViewController, _ completion: () -> Void) {
        viewController.view.alpha = 0.0
        UIView.animate(withDuration: fadeTime, delay: 0.0, options: .curveEaseIn, animations: {
            viewController.view.alpha = 1.0
        })
    }
}
