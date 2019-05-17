import Foundation

public struct BookResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Book]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
