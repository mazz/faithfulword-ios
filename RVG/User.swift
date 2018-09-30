import Foundation
import GRDB

public struct User: Codable {
    var userId: Int64?
    public var name: String
    public var session: String
    public var pushNotifications: Bool
    public var language: String
}

// Define colums so that we can build GRDB requests
extension User {
    enum Columns {
        static let name = Column("name")
        static let session = Column("session")
        static let pushNotifications = Column("pushNotifications")
        static let language = Column("language")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension User: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension User: MutablePersistableRecord {
    public static let databaseTableName = "user"
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        userId = rowID
    }
}
