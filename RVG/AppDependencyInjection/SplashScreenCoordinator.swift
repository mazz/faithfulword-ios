import UIKit
import RxSwift

/// Coordinator in charge of all navigation through the splash screen.

internal final class SplashScreenCoordinator {
    
    // MARK: Fields
    private var splashScreen: SplashScreenViewController!
    private var splashScreenNavigationController: UINavigationController!
    private var splashScreenFlowCompletion: FlowCompletion!
    
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

// MARK: <NavigationCoordinating>
extension SplashScreenCoordinator: NavigationCoordinating {
    
    /// Creates and sets up the splashScreenViewController and sets it as the root of
    /// the splashScreenNavigationController, triggers animation
    
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        let splashScreenViewController = uiFactory.makeSplashScreen()
        splashScreenNavigationController = UINavigationController(rootViewController: splashScreenViewController)
        splashScreen = SplashScreenViewController.create()
        setup(splashScreen)
        splashScreenViewController.plant(splashScreen)
        // Animate pulsing and bose in box
        splashScreen.animateText(AnimationConstants.splashScreenTransition ) { [weak self] in
            self?.splashScreen.remove()
            completion(.finished)
        }
    }
}
