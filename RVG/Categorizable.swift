import Foundation

public protocol Categorizable {
    var categoryUuid: String { get }
    var title: String { get }
    var languageId: String { get }
    var localizedTitle: String { get }
}

public enum CategoryListingType {
    case gospel
    case music
    case mediaItems
}

