import Foundation
import GRDB

public struct Book: Codable {
    var userId: Int64?
    public var categoryUuid: String
    public var title: String
    public var languageId: String
    public var localizedTitle: String

    enum CodingKeys: String, CodingKey {
        case userId
        case categoryUuid, uuid
        case title
        case languageId
        case localizedTitle
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(categoryUuid, forKey: .categoryUuid)
        try container.encode(title, forKey: .title)
        try container.encode(languageId, forKey: .languageId)
        try container.encode(localizedTitle, forKey: .localizedTitle)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.userId = try? values.decode(Int64.self, forKey: .userId)
        // take categoryUuid, if not exist then take uuid (at least one of them must present)
        self.categoryUuid = try values.decodeIfPresent(String.self, forKey: .categoryUuid)
            ?? (try values.decode(String.self, forKey: .uuid))
        self.title = try values.decode(String.self, forKey: .title)
        self.languageId = try values.decode(String.self, forKey: .languageId)
        self.localizedTitle = try values.decode(String.self, forKey: .localizedTitle)
    }
}

// Define columns so that we can build GRDB requests
extension Book {
    enum Columns {
        static let userId = Column("userId")
        static let categoryUuid = Column("categoryUuid")
        static let title = Column("title")
        static let languageId = Column("languageId")
        static let localizedTitle = Column("localizedTitle")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension Book: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension Book: MutablePersistableRecord {
    public static let databaseTableName = "book"
    public mutating func didInsert(with rowID: String, for column: String?) {
        categoryUuid = rowID
    }
}

