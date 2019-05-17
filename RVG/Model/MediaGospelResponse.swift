import Foundation

public struct MediaGospelResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [MediaGospel]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
