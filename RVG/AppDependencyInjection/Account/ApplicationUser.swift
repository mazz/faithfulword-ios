import Foundation
//import BoseMobileModels
//import RxSwift
//import BoseMobileUtilities

public class ApplicationUser {
    public let userSession: String // a session is a simple string for now
//    public internal(set) var accountInfo: PassportAccountInfo?
    
    public init(userSession: String) {
        self.userSession = userSession
    }
}
