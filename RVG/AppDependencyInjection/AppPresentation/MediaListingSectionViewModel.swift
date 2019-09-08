import Foundation
import RxDataSources

internal struct MediaListingSectionViewModel {
    internal let type: MediaListingSectionType
    internal let items: [MediaListingItemType]
}

internal enum MediaListingSectionType {
    case media
    case debug
}

internal enum MediaListingItemType {
    //    case field(String, String)
    //    case option(SettingOptionType)
    //    case action(name: String)
    case drillIn(type: MediaListingDrillInType, iconName: String, title: String, presenter: String, showBottomSeparator: Bool)
    //    case info(String)
}

public enum MediaListingDrillInType {
    case playable(item: Playable)
}

internal enum MediaListingActionType {
    case openMedia
}

extension MediaListingSectionViewModel: SectionModelType {
    typealias Item = MediaListingItemType
    init(original: MediaListingSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}
