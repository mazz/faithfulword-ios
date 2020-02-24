//
//  HistoryMediaViewModeling.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-24.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

public protocol HistoryMediaViewModeling {
    var media: Field<[Playable]> { get }
    var sections: Field<[MediaListingSectionViewModel]> { get }

    var filteredSections: Field<[MediaListingSectionViewModel]> { get }
    var filterText: PublishSubject<String> { get }
    
    var selectItemEvent: PublishSubject<IndexPath> { get }
    var emptyFilteredResult: Field<Bool> { get }
    var emptyFetchResult: Field<Bool> { get }

    
    var networkStatus: Field<ClassicReachability.NetworkStatus> { get }
    
    func section(at index: Int) -> MediaListingSectionViewModel
    func item(at indexPath: IndexPath) -> MediaListingItemType
}

