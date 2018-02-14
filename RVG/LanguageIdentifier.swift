import Foundation
import GRDB

public struct LanguageIdentifier: Codable {
    var uuid: String
    let sourceMaterial: String
    let languageIdentifier: String
    let supported: Bool
}

// Define columns so that we can build GRDB requests
extension LanguageIdentifier {
    enum Columns {
        static let uuid = Column("uuid")
        static let sourceMaterial = Column("sourceMaterial")
        static let languageIdentifier = Column("languageIdentifier")
        static let supported = Column("supported")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension LanguageIdentifier: RowConvertible { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension LanguageIdentifier: MutablePersistable {
    public static let databaseTableName = "languageidentifier"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}


