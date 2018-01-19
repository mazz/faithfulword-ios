import Foundation

public struct BookResponse: Codable {
    public var result: [Book]
    public var status: String
    public var version: String
}
