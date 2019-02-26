import Foundation
public struct MediaChapterResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [MediaChapter]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}

