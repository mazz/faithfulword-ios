import UIKit

public enum NoResourcehAnimationState {
    case initialized
    case animatingPulse
    case finished
}

public final class NoResourceViewController: UIViewController {
    private (set) public var animationState: NoResourcehAnimationState = .initialized
    
    @IBOutlet weak var titleMessage: UILabel!
    @IBOutlet weak var bodyMessage: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var viewModel: NoResourceViewModel!
    
    //    private var shouldEndPulsingAnimation: Bool = false
//    public var pulseLogoDuration: TimeInterval = 0.5
//    public var fadeOutDuration: TimeInterval = 0.2
//
//    private static let fullAlpha: CGFloat  = 1.0
//    private static let lowestAlpha: CGFloat = 0.0
//
//
//    @IBOutlet weak var manyLanguagesLabel: UILabel!
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        var internetReachable: Bool = false
        
        switch viewModel.appNetworkStatus {
        case .unknown, .notReachable:
            titleMessage.text = NSLocalizedString("Connect to the Internet", comment: "").l10n()
            bodyMessage.text = NSLocalizedString("You're offline. Check your connection.", comment: "").l10n()
            actionButton.setTitle(NSLocalizedString("Try Again", comment: "").l10n(), for: .normal)
        case .reachable(_):
            internetReachable = true
        }

        switch viewModel.serverStatus {
        case .none, .notConnected:
            if internetReachable {
                titleMessage.text = NSLocalizedString("Server Not Available", comment: "").l10n()
                bodyMessage.text = NSLocalizedString("You're online, but cannot connect. Please try again later.", comment: "").l10n()
                actionButton.setTitle(NSLocalizedString("Try Again", comment: "").l10n(), for: .normal)
            }
        case .connected:
            DDLogDebug("this should never reach here")
        }
        
//        self.manyLanguagesLabel.alpha = NoResourceViewController.fullAlpha
    }
    
    
    
    @IBAction func tryAgainAction(_ sender: Any) {
        
        viewModel.tapTryAgainEvent.onNext(viewModel.appFlowStatus)
    }
    //    public static func create() -> NoResourceViewController {
//        let storyboard = UIStoryboard(name: StoryboardName.splashScreen, bundle: nil)
//        let viewController = storyboard.instantiateViewController(withIdentifier: "NoResourceViewController") as? NoResourceViewController
//        return viewController ?? NoResourceViewController()
//    }
//
//
//    public func plant(_ plantedViewController: UIViewController) {
//        viewSafe { [unowned self] in
//            self.embed(plantedViewController,
//                       in: self.view)
//        }
//    }
//
    public func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
//    public func animateText(_ timeout: TimeInterval = 7.0, completion: (() -> Void)?) {
//
//        guard animationState != .animatingPulse else { return }
//        animationState = .animatingPulse
//        shouldEndPulsingAnimation = false
//
//        func fadeIn() {
//            UIView.animate(
//                withDuration: pulseLogoDuration,
//                delay: 0.0,
//                options: .curveEaseInOut,
//                animations: {
//                    //                    self?.manyLanguagesLabel.alpha = SplashScreenViewController.fullAlpha
//            },
//                completion: { _ in
//                    let delay = DispatchTime.now() + Double(Int64(1) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
//                    DispatchQueue.main.asyncAfter(deadline: delay) {
//                        fadeOut()
//                    }
//            }
//            )
//        }
//
//        func fadeOut() {
//            UIView.animate(
//                withDuration: pulseLogoDuration,
//                delay: 0.0,
//                options: .curveEaseInOut,
//                animations: { [weak self] in
//                    self?.manyLanguagesLabel.alpha = NoResourceViewController.lowestAlpha
//                },
//                completion: { _ in
//                    completion?()
//            }
//            )
//        }
//        fadeIn()
//    }
}
