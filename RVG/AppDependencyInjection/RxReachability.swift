import Foundation
import RxSwift
import Alamofire

public typealias ReachabilityStatus = NetworkReachabilityManager.NetworkReachabilityStatus

/// Protocol facade on Alamofire's NetworkReachabilityManager
public protocol NetworkReachabilityManaging {
    typealias Listener = (ReachabilityStatus) -> Void
    var listener: Listener? {get set}
    var networkReachabilityStatus: ReachabilityStatus { get }
    
    @discardableResult
    func startListening() -> Bool
    func stopListening()
}

extension NetworkReachabilityManager: NetworkReachabilityManaging {
}

/// An Rx wrapper around the reachability API from Alamofire.
public protocol RxReachable {
    
    /// Current reachability status event stream
    var status: Field<ReachabilityStatus> { get }
    
    /// Start listener.  Must call this for reachability updates to be published.
    ///
    /// - Returns: An observable for reachability status changes.  Will fire immediately 
    /// with current status.
    func startListening() -> Observable<ReachabilityStatus>
    
    /// Pauses publication of reachability status updates.
    func pauseListening()
    
    /// Stops publication of reachability status updates.  All existing subscriptions will
    /// receive an `onComplete` event.
    func stopListening()
}

/// Simple implementation of RxReachable
public final class RxReachability {
    
    // MARK: Fields
    
    public private(set) var status: Field<ReachabilityStatus>
    
    // MARK: Dependencies
    
    private let reachabilityManager: NetworkReachabilityManaging?
    
    /// Initializes an instance of RxReachability and hooks up internal callbacks for
    /// reachability updates.
    ///
    /// - Parameter reachabilityManager: The `NetworkReachabilityManager` to wrap.
    public init(reachabilityManager: NetworkReachabilityManaging?) {
        let startingStatus = reachabilityManager?.networkReachabilityStatus ?? .unknown
        status = Field<ReachabilityStatus>(startingStatus)
        
        self.reachabilityManager = reachabilityManager
        self.reachabilityManager?.listener = { [unowned self] status in
            print("reachability status changed: \(status)")
            self.status.value = status
        }
    }
    
    deinit {
        self.reachabilityManager?.stopListening()
    }
}

// MARK: <RxReachable>
extension RxReachability: RxReachable {
    
    public func startListening() -> Observable<ReachabilityStatus> {
        print("started reachability listener")
        self.reachabilityManager?.startListening()
        return status.asObservable()
    }
    
    public func pauseListening() {
        print("pausing reachability listener")
        self.reachabilityManager?.stopListening()
    }
    
    public func stopListening() {
        print("stopping reachability listener")
        self.reachabilityManager?.stopListening()
        let currentStatus = reachabilityManager?.networkReachabilityStatus ?? .unknown
        status = Field<ReachabilityStatus>(currentStatus)
    }
    
}
