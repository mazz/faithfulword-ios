import Foundation
import RxDataSources

public struct MediaListingSectionViewModel {
    public let type: MediaListingSectionType
    public var items: [MediaListingItemType]
}

public enum MediaListingSectionType {
    case media
    case debug
}

public enum MediaListingItemType {
    //    case field(String, String)
    //    case option(SettingOptionType)
    //    case action(name: String)
    case drillIn(type: MediaListingDrillInType, iconName: String, title: String, presenter: String, showBottomSeparator: Bool)
    //    case info(String)
}

public enum MediaListingDrillInType {
    case playable(item: Playable)
}

public enum MediaListingActionType {
    case openMedia
}

extension MediaListingSectionViewModel: SectionModelType {
    public typealias Item = MediaListingItemType
    public init(original: MediaListingSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}
