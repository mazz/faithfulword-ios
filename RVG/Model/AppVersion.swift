
import Foundation

public struct AppVersion: Codable {
    public var uuid: String
    public var iosSupported: Bool
    public var androidSupported: Bool
    public var versionNumber: String
}

