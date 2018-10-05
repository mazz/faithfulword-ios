import Foundation
import RxDataSources

internal struct SideMenuSectionViewModel {
    internal let type: SideMenuSectionType
    internal let items: [SideMenuItemType]
}

internal enum SideMenuSectionType {
    case menuItem
    case quote
}

internal enum SideMenuItemType {
    case drillIn(type: SideMenuDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
    case quote(body: String, chapterAndVerse: String)
}

public enum SideMenuDrillInType {
    case bible
    case gospel
//    case preaching
    case music
    case aboutUs
    case share
    case setBibleLanguage
    case donate
    case privacyPolicy
    case contactUs
}

extension SideMenuSectionViewModel: SectionModelType {
    typealias Item = SideMenuItemType
    init(original: SideMenuSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

public struct SideMenuItem {
    public var heading: SideMenuDrillInType
}
