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

    // MARK: Playback action handling
    public var progressEvent = PublishSubject<Float>()
//
//    public var latestPlaybackPosition: Observable<Double> {
//        if let playable = self.playable {
//            return self.userActionsService.fetchPlaybackPosition(playable: playable)
//                .asObservable()
//        } else {
//            return Observable.just(-1)
//        }
//    }

    // MARK: Dependencies
    private let userActionsService: UserActionsServicing!
    private let bag = DisposeBag()

    init(userActionsService: UserActionsServicing) {
        self.userActionsService = userActionsService
        setupBindings()
    }
    
    func setupBindings() {
        progressEvent.asObservable()
            .subscribe(onNext: { [unowned self] progressValue in
                DDLogDebug("progressValue: \(progressValue)")
                if let playable: Playable = self.playable {
                    self.userActionsService.updatePlaybackPosition(playable: playable, position: progressValue)
                        .asObservable()
                        .subscribeAndDispose(by: self.bag)
                }
            })
            .disposed(by: bag)
    }
}


