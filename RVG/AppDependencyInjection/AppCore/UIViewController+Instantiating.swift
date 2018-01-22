import Foundation
import UIKit


// In order to extend UIViewController to have a function returning Self, the extension must be on a protocol constrained to UIViewController.
public protocol LoadableFromStoryboard {}

extension UIViewController: LoadableFromStoryboard {}

public extension LoadableFromStoryboard where Self: UIViewController {
    
    /// Identifier name - i.e. name of class.  Used as default identifier for storyboard instantiation.
    private static var identifierName: String {
        return String(describing: self)
    }
    
    /// Instantiates a typed view controller from storyboard.
    /// Note that no static or dynamic property injection is performed on the instantiated view controller.  To understand the pattern for view controller dependency injection, see `UIFactory` for examples.
    ///
    /// - Parameters:
    ///   - storyboardName: Name of the storyboard to instantiate from.
    ///   - bundle: Bundle to instantiate from.  Defaults to main bundle.
    /// - Returns: An fresh uninjected instance of the view contoller.
    public static func make(storyboardName: String, bundle: Bundle = Bundle.main) -> Self {
        let storyboard = UIStoryboard(
            name: storyboardName,
            bundle: bundle
        )
        let viewController = storyboard.instantiateViewController(withIdentifier: identifierName)
            as? Self
        guard viewController != nil else {
            let errorMessage = "Could not instantiate view controller from the Storyboard. Check your storyboard identifiers and Swinject hookups."
            print(errorMessage)
            fatalError(errorMessage)
        }
        return viewController!
    }
    
}
