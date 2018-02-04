import Foundation
//import ObjectMapper

public struct Gospel: Codable, Categorizable {
    public var uuid: String
    public var title: String
    public var languageId: String
    public var localizedTitle: String

    enum CodingKeys: String, CodingKey {
        case uuid = "gid"
        case title
        case languageId
        case localizedTitle
    }
}

