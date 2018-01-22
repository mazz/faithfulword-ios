import Foundation
import UIKit

public extension UIView {
    
    /// Same as `fromNib(in bundle:)`, but always uses
    /// ModuleInfo.bundle bundle i.e. bundle of the UI module.
    ///
    /// - Returns: An instance of the view.
    public static func fromUiNib() -> Self {
        if let view = fromNib(in: ModuleInfo.bundle) {
            return view
        } else {
            fatalError("Failed to load nib")
        }
    }
    
    /// Same as `nib(in bundle:)`, but always uses
    /// ModuleInfo.bundle bundle i.e. bundle of the UI module.
    ///
    /// - Returns: Nib for the view from UI bundle.
    public static func uiNib() -> UINib {
        return nib(in: ModuleInfo.bundle)
    }
    
}
