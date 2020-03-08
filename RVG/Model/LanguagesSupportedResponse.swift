import Foundation

public struct LanguagesSupportedResponse: Codable {
    
    public var page_size: Int
    public var page_number: Int
    public var result: [LanguageIdentifier]
    public var status: String
    public var total_pages: Int
    public var total_entries: Int
    public var version: String

}
