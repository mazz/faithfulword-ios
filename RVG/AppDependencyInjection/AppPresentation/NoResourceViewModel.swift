//
//  NoResourceViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-10-05.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class NoResourceViewModel {
    // MARK: Fields
//    public var appFlowStatus: AppFlowStatus
//    public var appNetworkStatus: ClassicReachability.NetworkStatus
//    public var serverStatus: ServerConnectivityStatus
//    public func section(at index: Int) -> SideMenuSectionViewModel {
//        return sections.value[index]
//    }
//    
//    public func item(at indexPath: IndexPath) -> SideMenuItemType {
//        return section(at: indexPath.section).items[indexPath.item]
//    }
    
//    public private(set) var sections = Field<[SideMenuSectionViewModel]>([])
    public let tapTryAgainEvent = PublishSubject<Void>()
    
//    public var drillInEvent: Observable<SideMenuDrillInType> {
//        // Emit events by mapping a tapped index path to setting-option.
//        return self.selectItemEvent.filterMap { [unowned self] indexPath -> SideMenuDrillInType? in
//            let section = self.sections.value[indexPath.section]
//            let item = section.items[indexPath.item]
//            // Don't emit an event for anything that is not a 'drillIn'
//            if case .drillIn(let type, _, _, _) = item {
//                return type
//            }
//            return nil
//        }
//    }
    
    // MARK: Dependencies
    private var bag = DisposeBag()
    
    internal init(
//        appFlowStatus: AppFlowStatus,
//                  appNetworkStatus: ClassicReachability.NetworkStatus
//                  serverStatus: ServerConnectivityStatus
                  ) {
//        self.appFlowStatus = appFlowStatus
//        self.appNetworkStatus = appNetworkStatus
//        self.serverStatus = serverStatus
        setupDatasource()
    }
    
    // MARK: Private helpers
    
    private func setupDatasource() {
        //        sections.value =
//        let mediaMenuItems: [SideMenuItemType] = [
//            SideMenuItemType.drillIn(type: .bible,
//                                     iconName: "books-stack-of-three",
//                                     title: NSLocalizedString("Bible", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .gospel,
//                                     iconName: "candlelight",
//                                     title: NSLocalizedString("Soul-winning", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .preaching,
//                                     iconName: "preaching",
//                                     title: NSLocalizedString("Preaching", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .music,
//                                     iconName: "discs_icon_white",
//                                     title: NSLocalizedString("Music", comment: "").l10n(),
//                                     showBottomSeparator: true)
//        ]
//        let miscMenuItems: [SideMenuItemType] = [
//
//            SideMenuItemType.drillIn(type: .history,
//                                     iconName: "recents",
//                                     title: NSLocalizedString("History", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .setBibleLanguage,
//                                     iconName: "lang",
//                                     title: NSLocalizedString("Set Bible Language", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .donate,
//                                     iconName: "donate",
//                                     title: NSLocalizedString("Donate", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .aboutUs,
//                                     iconName: "about_ic",
//                                     title: NSLocalizedString("About Us", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .privacyPolicy,
//                                     iconName: "privacy_ic",
//                                     title: NSLocalizedString("Privacy Policy", comment: "").l10n(),
//                                     showBottomSeparator: true),
//            SideMenuItemType.drillIn(type: .contactUs,
//                                     iconName: "mail",
//                                     title: NSLocalizedString("Feedback", comment: "").l10n(),
//                                     showBottomSeparator: true)]
//        sections.value = [
//            SideMenuSectionViewModel(type: .menuItem, items: mediaMenuItems),
//            SideMenuSectionViewModel(type: .menuItem, items: miscMenuItems),
//            SideMenuSectionViewModel(type: .quote, items: [
//                SideMenuItemType.quote(body: NSLocalizedString("Holding fast the faithful word as he hath been taught, that he may be able by sound doctrine both to exhort and to convince the gainsayers.", comment: "").l10n(), chapterAndVerse: NSLocalizedString("Titus 1:9", comment: "").l10n())
//                ])
//        ]
    }
}


