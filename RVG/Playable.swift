import Foundation

public protocol Playable {
    var localizedName : String? { get set }
    var path : String? { get set }
    var presenterName : String? { get set }
    var sourceMaterial : String? { get set }
}

public protocol PlayableType: Playable {
    var iconName : String { get }
}

public protocol PlayableSermon: PlayableType { }
public protocol PlayableChapter: PlayableType { }
public protocol PlayableGospel: PlayableType { }

enum MediaType {
    case mediaChapter
    case mediaSermon
    case mediaGospel
}

