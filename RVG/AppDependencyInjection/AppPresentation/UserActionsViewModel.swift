//
//  UserActionsViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-03-08.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class UserActionsViewModel {
    // MARK: Fields
    
    // the asset that the user intends to download
    public var playable: Playable? = nil

    // MARK: from client
    public var progressEvent = PublishSubject<Float>()
    // (progress, duration)
    public var playbackEvent = PublishSubject<(Float, Float)>()

    // MARK: to client
    public var playbackHistory = PublishSubject<[Playable]>()

    // MARK: Dependencies
    private let userActionsService: UserActionsServicing!
    private let historyService: HistoryServicing!
    
    private let bag = DisposeBag()

    init(userActionsService: UserActionsServicing,
         historyService: HistoryServicing) {
        self.userActionsService = userActionsService
        self.historyService = historyService
        setupBindings()
    }
    
    func setupBindings() {
        playbackEvent.asObservable()
            .throttle(1.5, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [unowned self] progressValue, durationValue in
                DDLogDebug("progressValue: \(progressValue), durationValue: \(durationValue)")
                if let playable: Playable = self.playable {
                    self.userActionsService.updatePlaybackPosition(playable: playable, position: progressValue, duration: durationValue)
                        .asObservable()
                        .subscribeAndDispose(by: self.bag)
                    
                    self.historyService.fetchPlaybackHistory(limit: 0)
                        .asObservable()
                        .next({ playables in
                            self.playbackHistory.onNext(playables)
                        })
                }
            })
            .disposed(by: bag)

    }
}

