import Foundation

public struct ChannelResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Channel]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
