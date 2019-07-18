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
    func fetchLastUserActionPlayableState(for playableUuid: String) -> Single<UserActionPlayable?>
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
//                DDLogDebug("playables history: \(playables)")
            })
    }
// fetchLastState(for playableUuid: String) -> Single<Playable>
    public func fetchLastUserActionPlayableState(for playableUuid: String) -> Single<UserActionPlayable?> {
        return dataService.fetchLastUserActionPlayableState(for: playableUuid)
//            .do(onSuccess: { playable in
//                DDLogDebug("playable last state \(playable)")
//            })
    }
}
