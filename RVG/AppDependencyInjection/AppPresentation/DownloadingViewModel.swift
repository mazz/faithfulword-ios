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

    public var observableDownload: Observable<FileDownload> {
//        return downloadService.activeDownload(filename: downloadAsset?.uuid)
        var download: Observable<FileDownload>!
//
        if let downloadAsset = self.downloadAsset {
            download = downloadService.activeDownload(filename: downloadAsset.uuid)
                .catchError({ error in
                    throw error
                })
        }
        return download
    }

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

                    self.observableDownload.subscribe(onNext: { download in
                        self.fileDownload.value = download
                        // fileDownload state
                        self.downloadState.value = download.state
                        if self.downloadState.value == .complete {
                            self.downloadImageNameEvent.value = "share-box"
                        }

                        print("download: \(download.localUrl) | \(download.completedCount) / \(download.totalCount)(\(download.progress) | \(download.state) )")
                        print("self.downloadService.downloadMap: \(self.downloadService.downloadMap)")
                    }, onError: { error in
                        self.fileDownload.value = nil
                    })
                    .disposed(by: self.bag)
                }
            })
            .disposed(by: bag)
    }
}

