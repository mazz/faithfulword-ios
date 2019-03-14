//
//  HistoryService.swift
//  FaithfulWord
//
//  Created by Michael on 2019-03-13.
//  Copyright © 2019 KJVRVG. All rights reserved.
//
import Foundation
import RxSwift

protocol HistoryServicing {
    func fetchPlaybackHistory() -> Single<[Playable]>
}

public final class HistoryService: HistoryServicing {
    
    // MARK: Dependencies
    private let dataService: HistoryDataServicing
    
    public init(dataService: HistoryDataServicing) {
        self.dataService = dataService
    }
    
    public func fetchPlaybackHistory() -> Single<[Playable]> {
        return dataService.fetchPlayableHistory()
            .do(onSuccess: { playables in
                DDLogDebug("playables history: \(playables)")
            })
    }
}
