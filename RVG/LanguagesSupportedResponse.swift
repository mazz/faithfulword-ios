import Foundation

public struct LanguagesSupportedResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [LanguageIdentifier]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
