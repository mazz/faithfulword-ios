import Foundation

public protocol Playable {
    var hash_id: String { get set }
    var duration: TimeInterval { get set }
    var inserted_at: String { get set }
    var localizedname: String { get set }
    var language_id: String? { get set }
    var large_thumbnail_path : String? { get set }
    var media_category: String { get set }
    var med_thumbnail_path : String? { get set }
    var multilanguage: Bool { get set }
    var ordinal: Int? { get set }
    var path: String? { get set }
    var presenter_name: String? { get set }
    var playlist_uuid: String { get set }
    var small_thumbnail_path : String? { get set }
    var source_material: String? { get set }
    var track_number: Int? { get set }
    var presented_at: String? { get set }
    var published_at: String? { get set }
    var updated_at: String? { get set }
    var tags: [String]? { get set }
    var uuid: String { get set }
}

enum MediaType: Int {
    case audioChapter
    case audioGospel
    case audioMusic
    //    case audioSermon
}
