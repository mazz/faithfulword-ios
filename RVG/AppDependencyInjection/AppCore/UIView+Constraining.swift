import Foundation
import UIKit

public extension UIView {
    
    /// Embeds a subview that is constrained to the edges.
    ///
    /// - Parameter subview: The subview to embed.
    public func embedFilling(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        subview.pinToSuperEdges()
    }
    
    /// Pins to the edges of superview.
    public func pinToSuperEdges() {
        pinToSuper(withMargin: 0.0)
    }
    
    /// Pins to the edges of superview with margin.
    ///
    /// - Parameter margin: The space margin to use for edge pinning.
    public func pinToSuper(withMargin margin: CGFloat) {
        let top = NSLayoutConstraint(item: self,
                                     attribute: .top,
                                     relatedBy: .equal,
                                     toItem: superview,
                                     attribute: .top,
                                     multiplier: 1.0,
                                     constant: CGFloat(margin))
        let bottom = NSLayoutConstraint(item: self,
                                        attribute: .bottom,
                                        relatedBy: .equal,
                                        toItem: superview,
                                        attribute: .bottom,
                                        multiplier: 1.0,
                                        constant: CGFloat(margin))
        let leading = NSLayoutConstraint(item: self,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: superview,
                                         attribute: .leading,
                                         multiplier: 1.0,
                                         constant: CGFloat(margin))
        let trailing = NSLayoutConstraint(item: self,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: superview,
                                          attribute: .trailing,
                                          multiplier: 1.0,
                                          constant: CGFloat(margin))
        superview?.addConstraints([top, bottom, leading, trailing])
    }
    
    /// Pins the receiver's top to the top of the passed in view.
    ///
    /// - Parameter view: View to pin to
    public func pinTops(with view: UIView) {
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
    
    /// Pins the receiver's bottom to the bottom of the passed in view.
    ///
    /// - Parameter view: View to pin to
    public func pinBottoms(with view: UIView) {
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    /// Pins the receiver's leading edge to the leading edge of the passed in view.
    ///
    /// - Parameter view: View to pin to
    public func pinLeadings(with view: UIView) {
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    /// Pins the receiver's trailing edge to the trailing edge of the passed in view.
    ///
    /// - Parameter view: View to pin to
    public func pinTrailings(with view: UIView) {
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    /// Pins the receiver's top to the passed in anchor.
    ///
    /// - Parameter anchor: Anchor to pin to
    public func pinTop(to anchor: NSLayoutYAxisAnchor) {
        topAnchor.constraint(equalTo: anchor).isActive = true
    }
    
    /// Pins the receiver's bottom to the passed in anchor.
    ///
    /// - Parameter anchor: Anchor to pin to
    public func pinBottom(to anchor: NSLayoutYAxisAnchor) {
        bottomAnchor.constraint(equalTo: anchor).isActive = true
    }
    
    /// Pins the receiver's leading edge to the passed in anchor.
    ///
    /// - Parameter anchor: Anchor to pin to
    public func pinLeading(to anchor: NSLayoutXAxisAnchor) {
        leadingAnchor.constraint(equalTo: anchor).isActive = true
    }
    
    /// Pins the receiver's trailing edge to the passed in anchor.
    ///
    /// - Parameter anchor: Anchor to pin to
    public func pinTrailing(to anchor: NSLayoutXAxisAnchor) {
        trailingAnchor.constraint(equalTo: anchor).isActive = true
    }
}
