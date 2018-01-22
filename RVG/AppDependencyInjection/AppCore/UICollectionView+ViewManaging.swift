import UIKit

public extension UICollectionView {
    
    /// Registers a cell nib using the class name as identifier.
    /// The Nib must have the same name as cell class.
    ///
    /// - Parameters:
    ///   - cellType: Type of cell to register.
    ///   - bundle: Bundle to load nib from.  Defaults to main bundle.
    public func register<T: UICollectionViewCell>(cellType: T.Type, in bundle: Bundle = Bundle.main) {
        register(T.nib(in: bundle),
                 forCellWithReuseIdentifier: T.identifierName)
    }
    
    /// Safely dequeue a cell from the collection view using the cell's name as identifier
    /// Fatal error if unable to dequeue cell of type with this identifier.
    ///
    /// - Parameters:
    ///   - cellType: Type of cell to dequeue (type name will be used as identifier).
    ///   - indexPath: Index path to dequeue for.
    /// - Returns: A dequeue'd reusable instance of the requested cell
    public func dequeue<T: UICollectionViewCell>(cellType: T.Type, for indexPath: IndexPath, withReuseIdentifierSuffix reuseIdentifierSuffix: String = "") -> T {
        let identifier = T.identifierName + reuseIdentifierSuffix
        if let cell = dequeueReusableCell(withReuseIdentifier: identifier,
                                          for: indexPath) as? T {
            return cell
        }
        let error = "Unable to dequeue cell with identifier '\(identifier)', check to make sure that (1) you have registered the cell, (2) you have registered it with the correct identifier."
        fatalError(error)
    }
    
    /// Register a reusable header view using the class name as identifier
    /// The Nib must have the same name as view class.
    ///
    /// - Parameters:
    ///   - headerViewType: Type of view to register as header
    ///   - bundle: Bundle to load nib from.  Defaults to main bundle.
    public func register<T: UICollectionReusableView>(headerViewType: T.Type, in bundle: Bundle = Bundle.main) {
        register(T.nib(in: bundle),
                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                 withReuseIdentifier: T.identifierName)
    }
    
    /// Safely dequeue a reusable header view from the collection view using the view's name as indentifier.
    /// Fatal error if unable to dequeue view of type with this identifier.
    ///
    /// - Parameters:
    ///   - headerViewType: Type of header view to dequeue (type name will be used as identifier).
    ///   - indexPath: Index path to dequeue for.
    public func dequeue<T: UICollectionReusableView>(headerViewType: T.Type, for indexPath: IndexPath) -> T {
        let identifier = T.identifierName
        if let view = dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                       withReuseIdentifier: identifier,
                                                       for: indexPath) as? T {
            return view
        }
        let error = "Unable to dequeue header view with identifier '\(identifier)', check to make sure that (1) you have registered the view, (2) you have registered it with the correct identifier."
        fatalError(error)
    }
    
}
