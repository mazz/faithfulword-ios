import Foundation

public protocol Playable {
    var uuid: String { get set }
    var localizedName : String? { get set }
    var path : String? { get set }
    var presenterName : String? { get set }
    var sourceMaterial : String? { get set }
    var trackNumber : Int64? { get set }
    var createdAt : String? { get set }
    var updatedAt : String? { get set }
    var largeThumbnailPath : String? { get set }
    var smallThumbnailPath : String? { get set }
}

enum MediaType {
    case audioChapter
    case audioSermon
    case audioGospel
    case audioMusic
}
