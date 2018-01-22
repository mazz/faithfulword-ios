import Foundation

public extension Data {
    
    /// utf8 string representation of data
    public var utf8String: String? {
        return String(data: self, encoding: .utf8)
    }
    
}
