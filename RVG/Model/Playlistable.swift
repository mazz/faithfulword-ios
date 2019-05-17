import Foundation

public protocol Playlistable {
    var categoryUuid: String { get }
    var title: String { get }
    var languageId: String { get }
    var localizedTitle: String { get }
}

public enum PlaylistType {
    case gospel
    case music
    case preaching
}

