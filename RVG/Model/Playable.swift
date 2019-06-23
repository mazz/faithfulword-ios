import Foundation

public protocol Playable {
    var hashId: String { get set }
    var duration: TimeInterval { get set }
    var insertedAt: TimeInterval { get set }
    var localizedname: String { get set }
    var largeThumbnailPath : String? { get set }
    var mediaCategory: String { get set }
    var medThumbnailPath : String? { get set }
    var path: String? { get set }
    var presenterName: String? { get set }
    var playlistUuid: String { get set }
    var smallThumbnailPath : String? { get set }
    var sourceMaterial: String? { get set }
    var trackNumber: Int? { get set }
    var updatedAt: TimeInterval? { get set }
    var uuid: String { get set }
}

enum MediaType: Int {
    case audioChapter
    case audioGospel
    case audioMusic
    //    case audioSermon
}
