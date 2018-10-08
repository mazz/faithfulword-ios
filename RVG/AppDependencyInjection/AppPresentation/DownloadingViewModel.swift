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

    public private(set) var playableItem = Field<Playable?>(nil)

    // MARK: Dependencies
    private let downloadService: DownloadServicing!
    private let bag = DisposeBag()

    internal init(downloadService: DownloadServicing)
    {
        self.downloadService = downloadService

        setupDatasource()
    }

    private func setupDatasource() {

    }
}

