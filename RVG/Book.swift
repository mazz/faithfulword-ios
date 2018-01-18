import Foundation
import GRDB

public struct Book: Codable {
    var bookId: Int64?
    var userId: Int64?
    public var bid: String
    public var title: String
    public var languageId: String
    public var localizedTitle: String
}

// Define colums so that we can build GRDB requests
extension Book {
    enum Columns {
        static let userId = Column("userId")
        static let bid = Column("bid")
        static let title = Column("title")
        static let languageId = Column("languageId")
        static let localizedTitle = Column("localizedTitle")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension Book: RowConvertible { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension Book: MutablePersistable {
    public static let databaseTableName = "book"
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        bookId = rowID
    }
}

