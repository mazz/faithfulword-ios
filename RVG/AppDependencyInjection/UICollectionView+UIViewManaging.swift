import Foundation
import UIKit

public extension UICollectionView {
    
    /// Same as `register(cellType: in bundle:)`, but always uses
    /// ModuleInfo.bundle bundle i.e. bundle of the UI module.
    ///
    /// - Parameters cellType: Type of cell to register.
    public func registerUi<T: UICollectionViewCell>(cellType: T.Type, suffix: String = "") {
        register(T.nib(in: ModuleInfo.bundle, suffix: suffix),
                 forCellWithReuseIdentifier: T.identifierName + suffix)
    }
    
    /// Same as `register(headerViewType: in bundle:)`, but always uses
    /// ModuleInfo.bundle bundle i.e. bundle of the UI module.
    ///
    /// - Parameters headerViewType: Type of view to register as header
    public func registerUi<T: UICollectionReusableView>(headerViewType: T.Type) {
        register(T.nib(in: ModuleInfo.bundle),
                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                 withReuseIdentifier: T.identifierName)
    }
    
}
