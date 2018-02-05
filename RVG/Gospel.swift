import Foundation
import GRDB

public struct Gospel: Codable, Categorizable {
    var userId: Int64?
    public var uuid: String
    public var title: String
    public var languageId: String
    public var localizedTitle: String

//    enum CodingKeys: String, CodingKey {
//        case userId
//        case uuid = "gid"
//        case title
//        case languageId
//        case localizedTitle
//    }
}

// Define columns so that we can build GRDB requests
extension Gospel {
    enum Columns {
        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let title = Column("title")
        static let languageId = Column("languageId")
        static let localizedTitle = Column("localizedTitle")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension Gospel: RowConvertible { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension Gospel: MutablePersistable {
    public static let databaseTableName = "gospel"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

