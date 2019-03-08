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
    // the tap event initiated by the user
    public var cancelDownloadButtonTapEvent = PublishSubject<FileDownloadState>()
    // the tap event for the download share button
//    public var fileDownloadCompleteEvent = PublishSubject<FileDownload>()
    // the progress of the current download
//    public var fileDownload = Field<FileDownload?>(nil)

//    public var observableDownload: Observable<FileDownload> {
////        return downloadService.activeDownload(filename: downloadAsset?.uuid)
//        var download: Observable<FileDownload>!
////
//        if let downloadAsset = self.downloadAsset {
//            download = downloadService.activeDownload(filename: downloadAsset.uuid)
//                .catchError({ error in
//                    throw error
//                })
//        }
//        return download
//    }

    // the state of the current download
//    public var downloadState = Field<FileDownloadState>(.initial)
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
        cancelDownloadButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAsset = self.downloadAsset {
//                    downloadService.removeDownload(filename: downloadAsset.uuid)
                    downloadService.removeDownload(filename: downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")))
                        .asObservable()
                        .subscribeAndDispose(by: self.bag)
                }
            })
            .disposed(by: bag)

        downloadButtonTapEvent.asObservable()
            .subscribe(onNext: { currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAsset = self.downloadAsset {
                    DDLogDebug("downloadAsset.uuid: \(downloadAsset.uuid)")
                    downloadService.fetchDownload(url: downloadAsset.urlAsset.url.absoluteString, filename: downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")))

//                    self.observableDownload.subscribe(onNext: { download in
//                        self.fileDownload.value = download
//                        // fileDownload state
//                        self.downloadState.value = download.state
//
//                        self.updateDownloadState(filename: downloadAsset.uuid, downloadState: download.state)
//
//                        //                        DDLogDebug("download: \(download.localUrl) | \(download.completedCount) / \(download.totalCount)(\(download.progress) | \(download.state) )")
//                        DDLogDebug("self.downloadService.downloadMap: \(self.downloadService.downloadMap)")
//                    }, onError: { error in
//                        DDLogDebug("observableDownload error: \(error)")
//                        self.fileDownload.value = nil
//                    })
//                    .disposed(by: self.bag)
                }
            }, onError: { error in
                DDLogDebug("downloadButtonTapEvent error: \(error)")
            })
            .disposed(by: bag)
    }

//    func removeDownload(for uuid: String) {
//        downloadService.removeDownload(filename: uuid)
//    }
    
//    public func updateDownloadState(filename: String, downloadState: FileDownloadState) {
//        if let downloadAsset = self.downloadAsset {
//            switch downloadState {
//            case .initial:
//                self.downloadImageNameEvent.value = "download_icon_black"
//            case .initiating:
//                break
//            case .inProgress:
//                break
//            case .cancelling:
//                break
//            case .cancelled:
////                downloadService.removeDownload(filename: downloadAsset.uuid)
//                self.downloadState.value = .initial
//            case .complete:
//                self.downloadImageNameEvent.value = "share-box"
////                downloadService.removeDownload(filename: downloadAsset.uuid)
//                self.downloadButtonTapEvent.dispose()
//                if let download = self.fileDownload.value {
//                    self.fileDownloadCompleteEvent.onNext(download)
//                }
//            case .error:
////                downloadService.removeDownload(filename: downloadAsset.uuid)
//                self.downloadState.value = .initial
//            case .unknown:
//                break
//            }
//        }
//    }
}

