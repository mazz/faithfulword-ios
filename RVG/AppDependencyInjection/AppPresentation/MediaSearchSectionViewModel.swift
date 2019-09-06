import Foundation
import RxDataSources

internal struct MediaDetailsSectionViewModel {
    internal let type: MediaDetailsSectionType
    internal let items: [MediaDetailsItemType]
}

internal enum MediaDetailsSectionType {
    case details
    case menuItem
}

internal enum MediaDetailsItemType {
    case details(
        localizedname: String,
        presenterName: String,
        sourceMaterial: String,
        presentedAt: TimeInterval?)
    case drillIn(
        type: MediaDetailsDrillInType,
        iconName: String,
        title: String,
        showBottomSeparator: Bool)
}

public enum MediaDetailsDrillInType {
    case playable(item: Playable)
}

extension MediaDetailsSectionViewModel: SectionModelType {
    typealias Item = MediaDetailsItemType
    init(original: MediaDetailsSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

public struct MediaDetailsItem {
    public var heading: MediaDetailsDrillInType
}
