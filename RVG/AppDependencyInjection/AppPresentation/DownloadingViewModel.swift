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
    public var downloadAsset: Asset? = nil
    public private(set) var downloadProgress: Field<Float> = Field<Float>(0)
//    public private(set) var downloadProgress: Field<Float> = Field<Float>(0)

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
                    let downloadAsset = self.downloadAsset {

                        downloadService.fetchDownload(url: downloadAsset.urlAsset.url.absoluteString, filename: downloadAsset.uuid)
                }
            })
            .disposed(by: bag)

        downloadService.progress
            .next({ progress in
                print("downloadService progress: \(progress)")
                self.downloadProgress.value = progress
            })
            .disposed(by: bag)

        downloadService.state.next { downloadState in
            print("downloadState: \(downloadState)")
            }
            .disposed(by: bag)


        downloadService.fileDownload.next { fileDownload in
            print("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress))")
            }
            .disposed(by: bag)
    }
}

