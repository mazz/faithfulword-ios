
import Foundation

class Environment {
    public var baseURL : NSURL?
    public var name : String?
    
    required init?(url: NSURL, name: String) {
        baseURL = url
        self.name = name
    }

}
