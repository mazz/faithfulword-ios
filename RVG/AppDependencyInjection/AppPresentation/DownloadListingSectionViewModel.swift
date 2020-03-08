//
//  DownloadListingSectionViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2020-03-07.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxDataSources

public struct DownloadListingSectionViewModel {
    public let type: DownloadListingSectionType
    public var items: [DownloadListingItemType]
}

public enum DownloadListingSectionType {
    case download
    case debug
}

public enum DownloadListingItemType {
    //    case field(String, String)
    //    case option(SettingOptionType)
    //    case action(name: String)
    case drillIn(type: DownloadListingDrillInType, iconName: String, title: String, presenter: String, showBottomSeparator: Bool)
    //    case info(String)
}

public enum DownloadListingDrillInType {
    case playable(item: Playable)
}

public enum DownloadListingActionType {
    case openMedia
}

extension DownloadListingSectionViewModel: SectionModelType {
    public typealias Item = DownloadListingItemType
    public init(original: DownloadListingSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

