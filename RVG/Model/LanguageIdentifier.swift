import Foundation
import GRDB

public struct LanguageIdentifier: Codable {
    var uuid: String
    let source_material: String
    let language_identifier: String
    let supported: Bool
}

// Define columns so that we can build GRDB requests
extension LanguageIdentifier {
    enum Columns {
        static let uuid = Column("uuid")
        static let source_material = Column("source_material")
        static let language_identifier = Column("language_identifier")
        static let supported = Column("supported")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension LanguageIdentifier: FetchableRecord, PersistableRecord { }
