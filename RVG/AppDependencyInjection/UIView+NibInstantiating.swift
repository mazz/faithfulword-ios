import Foundation
import UIKit

public protocol LoadableFromNib {}

extension UIView: LoadableFromNib {}

public extension LoadableFromNib where Self: UIView {
    
    /// Inflates an instance of the view from bundle.
    ///
    /// - Parameter bundle: Bundle to load from.  Defaults to main bundle.
    /// - Returns: An instance of the view.
    public static func fromNib(in bundle: Bundle = Bundle.main, suffix: String = "") -> Self? {
        if let views = bundle.loadNibNamed(String(describing: self) + suffix,
                                            owner: nil,
                                            options: nil) {
            return views.filter { $0 is Self }.first as? Self
        }
        return nil
    }
    
    /// Inflates nib for view.
    ///
    /// - Parameter bundle: Bundle to load from.  Defaults to main bundle.
    /// - Returns: Nib for the view from specified bundle.
    public static func nib(in bundle: Bundle = Bundle.main, suffix: String = "") -> UINib {
        return UINib(nibName: String(describing: self) + suffix,
                     bundle: bundle)
    }
    
    /// Identifier name - i.e. name of view.  Used as default identifier for cell registrations and such.
    public static var identifierName: String {
        return String(describing: self)
    }
    
}
