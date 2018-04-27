import Foundation
import GRDB

public struct MediaChapter: Codable, Playable {
//    var bookId: Int64?
//    var userId: Int64?
    public var uuid: String
    public var localizedName: String?
    public var path: String?
    public var presenterName: String?
    public var sourceMaterial: String?
    public var categoryUuid: String?
    public var trackNumber: Int64?
    public var createdAt: Date?
    public var updatedAt: Date?
    public var largeThumbnailPath: String?
    public var smallThumbnailPath: String?
}

// Define columns so that we can build GRDB requests
extension MediaChapter {
    enum Columns {
//        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let localizedName = Column("localizedName")
        static let path = Column("path")
        static let presenterName = Column("presenterName")
        static let sourceMaterial = Column("sourceMaterial")
        static let categoryUuid = Column("categoryUuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaChapter: RowConvertible { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension MediaChapter: MutablePersistable {
    public static let databaseTableName = "mediachapter"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

