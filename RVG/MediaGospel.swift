import Foundation
import GRDB

/*
 "localizedName": "Σχέδιο σωτηρίας (Greek)",
 "path": "gospel/el/BibleWayToHeaven-Unattributed-el.mp3",
 "sourceMaterial": null,
 "presenterName": "Unattributed",
 "uuid": "7135d992-1e86-4902-86e6-4e34ea159cd0",
 "trackNumber": null,
 "createdAt": "2018-04-17 02:04:13",
 "largeThumbnailPath": null,
 "updatedAt": null,
 "smallThumbnailPath": null
 */

public struct MediaGospel: Codable, Playable {
    //    var bookId: Int64?
    //    var userId: Int64?
    public var uuid: String
    public var localizedName: String?
    public var path: String?
    public var presenterName: String?
    public var sourceMaterial: String?
    public var categoryUuid: String?
    public var trackNumber: Int64?
    public var createdAt: String?
    public var updatedAt: String?
    public var largeThumbnailPath: String?
    public var smallThumbnailPath: String?
}

// Define columns so that we can build GRDB requests
extension MediaGospel {
    enum Columns {
        //        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let localizedName = Column("localizedName")
        static let path = Column("path")
        static let presenterName = Column("presenterName")
        static let sourceMaterial = Column("sourceMaterial")
        static let categoryUuid = Column("categoryUuid")
        static let trackNumber = Column("trackNumber")
        static let createdAt = Column("createdAt")
        static let updatedAt = Column("updatedAt")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaGospel: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension MediaGospel: MutablePersistableRecord {
    public static let databaseTableName = "mediagospel"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

