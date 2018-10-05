import Foundation
import RxSwift

internal final class SideMenuViewModel {
    // MARK: Fields

    public func section(at index: Int) -> SideMenuSectionViewModel {
        return sections.value[index]
    }

    public func item(at indexPath: IndexPath) -> SideMenuItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public private(set) var sections = Field<[SideMenuSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()

    public var drillInEvent: Observable<SideMenuDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> SideMenuDrillInType? in
            let section = self.sections.value[indexPath.section]
            let item = section.items[indexPath.item]
            // Don't emit an event for anything that is not a 'drillIn'
            if case .drillIn(let type, _, _, _) = item {
                return type
            }
            return nil
        }
    }

    // MARK: Dependencies
    private var bag = DisposeBag()

    internal init() {
        setupDatasource()
    }

    // MARK: Private helpers

    private func setupDatasource() {
        //        sections.value =
        let menuItems: [SideMenuItemType] = [
            SideMenuItemType.drillIn(type: .bible,
                                     iconName: "books-stack-of-three",
                                     title: NSLocalizedString("Bible", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .gospel,
                                     iconName: "candlelight",
                                     title: NSLocalizedString("Soul-winning", comment: "").l10n(),
                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .preaching,
//                                     iconName: "preaching",
//                                     title: NSLocalizedString("Preaching", comment: "").l10n(),
//                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .music,
                                     iconName: "discs_icon_white",
                                     title: NSLocalizedString("Music", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .setBibleLanguage,
                                     iconName: "language_menu",
                                     title: NSLocalizedString("Set Bible Language", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .share,
                                     iconName: "share_ic",
                                     title: NSLocalizedString("Share", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .donate,
                                     iconName: "donate",
                                     title: NSLocalizedString("Donate", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .aboutUs,
                                     iconName: "about_ic",
                                     title: NSLocalizedString("About Us", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .privacyPolicy,
                                     iconName: "privacy_ic",
                                     title: NSLocalizedString("Privacy Policy", comment: "").l10n(),
                                     showBottomSeparator: true),
            SideMenuItemType.drillIn(type: .contactUs,
                                     iconName: "mail",
                                     title: NSLocalizedString("Feedback", comment: "").l10n(),
                                     showBottomSeparator: true)]
        sections.value = [
            SideMenuSectionViewModel(type: .menuItem, items: menuItems),
            SideMenuSectionViewModel(type: .quote, items: [
                SideMenuItemType.quote(body: NSLocalizedString("Holding fast the faithful word as he hath been taught, that he may be able by sound doctrine both to exhort and to convince the gainsayers.", comment: "").l10n(), chapterAndVerse: NSLocalizedString("Titus 1:9", comment: "").l10n())
                ])
        ]
    }
}


