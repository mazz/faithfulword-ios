import Foundation

public protocol Playable {
    var localizedName : String? { get set }
    var path : String? { get set }
    var presenterName : String? { get set }
    var sourceMaterial : String? { get set }
}

enum MediaType {
    case audioChapter
    case audioSermon
    case audioGospel
}

