//
//  HistoryDownloadViewModeling.swift
//  FaithfulWord
//
//  Created by Michael on 2020-03-07.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

public protocol HistoryDownloadViewModeling {
    var downloads: Field<[FileDownload]> { get }
    var sections: Field<[DownloadListingSectionViewModel]> { get }
    var historyHorizon: Int { get }

    var filteredSections: Field<[DownloadListingSectionViewModel]> { get }
    var filterText: PublishSubject<String> { get }
    
    var selectItemEvent: PublishSubject<IndexPath> { get }
    var drillInEvent: Observable<DownloadListingDrillInType> { get }
    var emptyFilteredResult: Field<Bool> { get }
    var emptyFetchResult: Field<Bool> { get }

    var fetchAppendMedia: PublishSubject<Bool> { get }
    
    var networkStatus: Field<ClassicReachability.NetworkStatus> { get }
    
    func section(at index: Int) -> DownloadListingSectionViewModel
    func item(at indexPath: IndexPath) -> DownloadListingItemType
}

