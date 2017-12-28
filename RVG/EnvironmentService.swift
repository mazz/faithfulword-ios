
import Foundation

class EnvironmentService {
    static var environmentService :  EnvironmentService?
    
    internal var connected : Environment = Environment(url: NSURL(string: EnvironmentUrlItemKey.ProductionServerRootUrl.rawValue)!, name: "production")!
    
    class func sharedInstance() -> EnvironmentService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.environmentservice") {
            environmentService = EnvironmentService()

        }
        return environmentService!
    }
    
    func connectedEnvironment() -> Environment {
        return connected
    }

}
