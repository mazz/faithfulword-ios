import UIKit
import Foundation

public enum UIViewSizingError: Error {
    case xibIdentifierMismatch
}

public extension UIView {
    internal static var map: [String: UIView] = [:]
    
    public static func sizingView<T: UIView>(for type: T.Type, suffix: String = "", bundle: Bundle = .main) throws -> T {
        let identifier = T.identifierName
        if map[identifier] == nil {
            map[identifier] = T.fromNib(in: bundle, suffix: suffix)
        }
        
        guard let sizingView = map[identifier] as? T else {
            throw UIViewSizingError.xibIdentifierMismatch
        }
                
        return sizingView
    }
    
    /// Uses cocoa rendering machinery to return the optimal view height for width
    ///
    /// - Parameter width: width of view
    /// - Returns: optimal height
    public func height(for width: CGFloat) -> CGFloat {
        // temp store the mask flag for view because we need to set it to
        // false in order to tell cocoa to IGNORE possible
        // autoresizing mask directives while calculating height
        let originalMaskFlag = translatesAutoresizingMaskIntoConstraints
        
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: self,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant: width)
        addConstraint(widthConstraint)
        
        // dirty view relayout so systemLayoutSizeFitting() will have an impact
        setNeedsLayout()
        layoutIfNeeded()
        let height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        removeConstraint(widthConstraint)
        translatesAutoresizingMaskIntoConstraints = originalMaskFlag
        
        return height
    }
    
    /// Uses cocoa rendering machinery to return the optimal view width for height
    ///
    /// - Parameter height: height of view
    /// - Returns: optimal width
    public func width(for height: CGFloat) -> CGFloat {
        // temp store the mask flag for view because we need to set it to
        // false in order to tell cocoa to IGNORE possible
        // autoresizing mask directives while calculating width
        let originalMaskFlag = translatesAutoresizingMaskIntoConstraints
        
        translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = NSLayoutConstraint(item: self,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: height)

        addConstraint(heightConstraint)
        
        // dirty view relayout so systemLayoutSizeFitting() will have an impact
        setNeedsLayout()
        layoutIfNeeded()
        let width = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        
        removeConstraint(heightConstraint)
        translatesAutoresizingMaskIntoConstraints = originalMaskFlag
        
        return width
    }
    
    public func canFitContents(inWidth width: CGFloat) -> Bool {
        let size = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return size.width <= width
    }
}
