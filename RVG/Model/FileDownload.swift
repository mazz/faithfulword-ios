import Foundation
import GRDB

public protocol FileDownloadable {
    var uuid: String { get }
    var playableUuid: String { get }
    var insertedAt: TimeInterval { get }
    var updatedAt: TimeInterval { get }
    var fileDownloadState: String { get }
    var userUuid: String { get }
}

public struct FileDownload: Codable {
    // MARK: Fields
    var url: URL
    var uuid: String
    var playableUuid: String
    var localUrl: URL
    var updatedAt: TimeInterval
    var insertedAt: TimeInterval
    var progress: Float
    var totalCount: Int64
    var completedCount: Int64
    var state: FileDownloadState
    
    //
    // a FileDownload is many-to-one to User
    //
    static let downloaditemForeignKey = ForeignKey([Columns.userUuid])
    
    init(url: URL,
         uuid: String,
         playableUuid: String,
         localUrl: URL,
         updatedAt: TimeInterval,
         insertedAt: TimeInterval,
         progress: Float,
         totalCount: Int64,
         completedCount: Int64,
         state: FileDownloadState) {
        self.url = url
        self.uuid = uuid
        self.playableUuid = playableUuid
        self.localUrl = localUrl
        self.updatedAt = updatedAt
        self.insertedAt = insertedAt
        self.progress = progress
        self.totalCount = totalCount
        self.completedCount = completedCount
        self.state = state
    }
    
}

// Define columns so that we can build GRDB requests
extension FileDownload {
    enum Columns {
        static let uuid = Column("uuid")
        static let playableUuid = Column("playableUuid")
        static let url = Column("url")
        static let localUrl = Column("localUrl")
        static let progress = Column("progress")
        static let totalCount = Column("totalCount")
        static let completedCount = Column("completedCount")
        static let updatedAt = Column("updatedAt")
        static let insertedAt = Column("insertedAt")
        static let state = Column("state")
        static let userUuid = Column("userUuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension FileDownload: FetchableRecord, PersistableRecord { }


extension FileDownloadState: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .initial
        case 1:
            self = .initiating
        case 2:
            self = .inProgress
        case 3:
            self = .cancelling
        case 4:
            self = .cancelled
        case 5:
            self = .complete
        case 6:
            self = .error
        case 7:
            self = .unknown
        default:
            throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .initial:
            try container.encode(0, forKey: .rawValue)
        case .initiating:
            try container.encode(1, forKey: .rawValue)
        case .inProgress:
            try container.encode(2, forKey: .rawValue)
        case .cancelling:
            try container.encode(3, forKey: .rawValue)
        case .cancelled:
            try container.encode(4, forKey: .rawValue)
        case .complete:
            try container.encode(5, forKey: .rawValue)
        case .error:
            try container.encode(6, forKey: .rawValue)
        case .unknown:
            try container.encode(7, forKey: .rawValue)
        }
    }
}

public enum FileDownloadState {
    case initial
    case initiating
    case inProgress
    case cancelling
    case cancelled
    case complete
    case error
    case unknown
}
