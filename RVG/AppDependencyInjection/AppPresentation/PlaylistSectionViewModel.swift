import Foundation
import RxDataSources

internal struct PlaylistSectionViewModel {
    internal let type: PlaylistSectionType
    internal let items: [PlaylistItemType]
}

internal enum PlaylistSectionType {
    case playlist
    case debug
}

internal enum PlaylistItemType {
    case drillIn(type: PlaylistDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
}

public enum PlaylistDrillInType {
    case playlistItemType(item: Playlist, mediaCategory: String)
}

extension PlaylistSectionViewModel: SectionModelType {
    typealias Item = PlaylistItemType
    init(original: PlaylistSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

