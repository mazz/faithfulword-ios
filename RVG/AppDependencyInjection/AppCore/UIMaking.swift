import Foundation
import Swinject

/// Basic enforcement of what a VC/VM factory should do
/// i.e. take a resolver & instantiate VC/VM's at runtime
public protocol UIMaking {
    init(resolver: Resolver)
}
