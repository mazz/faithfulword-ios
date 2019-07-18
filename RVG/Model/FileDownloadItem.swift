import Foundation
import GRDB

public protocol FileDownloadable {
    var uuid: String { get }
    var playableUuid: String { get }
    var insertedAt: TimeInterval { get }
    var updatedAt: TimeInterval? { get }
    var fileDownloadState: String { get }
    var userUuid: String { get }
}

public struct FileDownloadItem: Codable, FileDownloadable {
    public var uuid: String
    public var playableUuid: String
    public var insertedAt: TimeInterval
    public var updatedAt: TimeInterval?
    public var fileDownloadState: String
    public var userUuid: String

    //
    // a FileDownloadItem is many-to-one to User
    //
    static let downloaditemForeignKey = ForeignKey([Columns.userUuid])
}

// Define columns so that we can build GRDB requests
extension FileDownloadItem {
    enum Columns {
        static let uuid = Column("uuid")
        static let playableUuid = Column("playableUuid")
        static let updatedAt = Column("updatedAt")
        static let insertedAt = Column("insertedAt")
        static let fileDownloadState = Column("fileDownloadState")
        static let userUuid = Column("userUuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension FileDownloadItem: FetchableRecord, PersistableRecord { }
