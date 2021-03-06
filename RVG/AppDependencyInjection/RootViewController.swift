import UIKit
import RxSwift

/// The bottom level view controller that all navigation flows stem from (lives for the entire lifetime of the app)
final class RootViewController: UIViewController {
    
    // MARK: Fields
    
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    public var reachability: RxClassicReachable!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeAndHandleReachabilityEvents()
    }
    
    // MARK: Public
    
    /// Adds a child-view-controller and embeds it into the view with animation. Takes optional animation param, defaulted to nil.  Also removes previous embeded child-view-controller
    ///
    /// - Parameter viewController: The view controller to be embeded.
    internal func plant(_ viewController: UIViewController, withAnimation animation: AppAnimations.Animatable? = nil) {
        if let residualPresentedViewController = children.first?.presentedViewController {
            residualPresentedViewController.dismiss(animated: true, completion: nil)
        }
        replace(children.first, with: viewController, in: view, withAnimation: animation)
    }
    
    
    // MARK: Private helpers
    
    private func subscribeAndHandleReachabilityEvents() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { [unowned self] networkStatus in
                switch networkStatus {
                case .unknown, .notReachable:
                    DDLogDebug("RootViewController \(self.reachability.status.value)")
                    self.showNoWifiAlert()
                case .reachable(_):
                    DDLogDebug("RootViewController \(self.reachability.status.value)")
                }
            }).disposed(by: bag)
        

    }
    
    private func showNoWifiAlert() {
        DDLogDebug("Wifi connection lost")
//        let alert = UIAlertController(title: "⚠️",
//                                      message: "Wifi connection lost",
//                                      preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "Ok",
//                                     style: .default)
//        alert.addAction(okAction)
//        present(alert,
//                animated: true,
//                completion: nil)
    }
    
}
