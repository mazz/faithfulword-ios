import Foundation
import UIKit

public extension UIImage {
    
    /// Same as `asset(name: in bundle:)`, but always uses
    /// ModuleInfo.bundle bundle i.e. bundle of the UI module.
    ///
    /// - Parameter name: Name of asset to load.
    /// - Returns: `UIImage` with the loaded asset.
    public static func uiAsset(name: String) -> UIImage? {
        return UIImage(named: name,
                       in: Bundle.main,
                       compatibleWith: nil)
    }
    
}
