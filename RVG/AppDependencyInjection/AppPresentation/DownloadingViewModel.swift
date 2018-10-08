//
//  DownloadingViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-08.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation

import Foundation
import RxSwift

internal final class DownloadingViewModel {
    // MARK: Fields
    public var downloadButtonTapEvent = PublishSubject<DownloadSetting>()

    // MARK: Dependencies
    private let downloadService: DownloadServicing!
    private let bag = DisposeBag()

    internal init(downloadService: DownloadServicing)
    {
        self.downloadService = downloadService

        setupBindings()
    }

    private func setupBindings() {
        downloadButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                print("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let dowloadSetting = currentSetting.element {
                    //                    let assetPlaybackManager = assetPlaybackService.assetPlaybackManager
                    //                    assetPlaybackManager.repeatState = repeatSetting
                }
            })
            .disposed(by: bag)
    }
}

