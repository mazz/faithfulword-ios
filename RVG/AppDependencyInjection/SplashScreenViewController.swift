import UIKit

public enum SplashAnimationState {
    case initialized
    case animatingPulse
    case finished
}

public final class SplashScreenViewController: UIViewController {
    private (set) public var animationState: SplashAnimationState = .initialized
    private var shouldEndPulsingAnimation: Bool = false
    public var pulseLogoDuration: TimeInterval = 0.5
    public var fadeOutDuration: TimeInterval = 0.2

    private static let fullAlpha: CGFloat  = 1.0
    private static let lowestAlpha: CGFloat = 0.0

    
    @IBOutlet weak var manyLanguagesLabel: UILabel!
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.manyLanguagesLabel.alpha = SplashScreenViewController.lowestAlpha
    }
    
    public static func create() -> SplashScreenViewController {
        let storyboard = UIStoryboard(name: StoryboardName.splashScreen, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SplashScreenViewController") as? SplashScreenViewController
        return viewController ?? SplashScreenViewController()
    }


    public func plant(_ plantedViewController: UIViewController) {
        viewSafe { [unowned self] in
            self.embed(plantedViewController,
                       in: self.view)
        }
    }
    
    public func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    public func animateText(_ timeout: TimeInterval = 7.0, completion: (() -> Void)?) {
        
        guard animationState != .animatingPulse else { return }
        animationState = .animatingPulse
        shouldEndPulsingAnimation = false
        
        func fadeIn() {
            UIView.animate(
                withDuration: pulseLogoDuration,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: { [weak self] in
                    self?.manyLanguagesLabel.alpha = SplashScreenViewController.fullAlpha
                },
                completion: { _ in
                    let delay = DispatchTime.now() + Double(Int64(3) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delay) {
                        fadeOut()
                    }
                }
            )
        }
        
        func fadeOut() {
            UIView.animate(
                withDuration: pulseLogoDuration,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: { [weak self] in
                    self?.manyLanguagesLabel.alpha = SplashScreenViewController.lowestAlpha
                },
                completion: { _ in
                        completion?()
                }
            )
        }

        fadeIn()
    }
}
