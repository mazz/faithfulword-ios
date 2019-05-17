import Foundation

public struct GospelResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Gospel]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}

