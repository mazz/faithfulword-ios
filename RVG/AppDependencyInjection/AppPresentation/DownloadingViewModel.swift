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

    // the asset that the user intends to download
    public var downloadAsset: Asset? = nil
    // the tap event initiated by the user
    public var downloadButtonTapEvent = PublishSubject<FileDownloadState>()
    // the progress of the current download
    public var fileDownload = Field<FileDownload?>(nil)
    // the state of the current download
    public var downloadState = Field<FileDownloadState>(.initial)
    // the state of the download button image name
    public let downloadImageNameEvent = Field<String>("download_icon_black")
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

        //        downloadService.progress
        //            .next({ progress in
        //                print("downloadService progress: \(progress)")
        //                self.downloadProgress.value = progress
        //            })
        //            .disposed(by: bag)

        downloadService.state.next { downloadState in
            print("downloadState: \(downloadState)")
            self.downloadState.value = downloadState

            if self.downloadState.value == .complete {
                self.downloadImageNameEvent.value = "share-box"
            }
            }
            .disposed(by: bag)


        downloadService.fileDownload.next { fileDownload in

            self.fileDownload.value = fileDownload

            print("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress))")
            }
            .disposed(by: bag)
    }
}

