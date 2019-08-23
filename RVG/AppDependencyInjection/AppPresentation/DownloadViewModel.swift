//
//  DownloadingViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-08.
//  Copyright © 2018 KJVRVG. All rights reserved.
//
import Foundation
import RxSwift

internal final class DownloadViewModel {
    // MARK: Fields

    // MARK: from client
    // the asset that the user intends to download
//    public var downloadAsset = Field<Asset?>(nil)
    //<uuid>.mp3
    public var downloadAssetIdentifier = Field<String?>(nil)
    //https: //remoteurl.com/full/path.mp3
    public var downloadAssetRemoteUrlString = Field<String?>(nil)
    // the tap event initiated by the user
    public var downloadButtonTapEvent = PublishSubject<FileDownloadState>()
    // the tap event initiated by the user
    public var cancelDownloadButtonTapEvent = PublishSubject<FileDownloadState>()
    
    // MARK: to client
    public var downloadState = PublishSubject<FileDownloadState>()
    
    public var downloadNotStarted = Field<Bool>(false)
    public var downloadStarting = Field<Bool>(false)
    public var downloadInProgress = Field<Bool>(false)
    public var completedDownload = Field<Bool>(false)

    // the state of the download button image name
    public let downloadImageNameEvent = Field<String>("download_icon_black")
    // MARK: Dependencies
    private let downloadService: DownloadServicing!
    private let bag = DisposeBag()

    internal init(downloadService: DownloadServicing)
    {
        self.downloadService = downloadService
        setupBindings()
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleUserDidTapCancelNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)

        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadViewModel.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)
    }
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default

        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)

        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidErrorNotification, object: nil)

    }
    
    public func storedFileDownload(for playableUuid: String) -> Single<FileDownload?> {
        return self.downloadService.fetchFileDownloadHistory(playableUuid: playableUuid)
    }

    private func setupBindings() {
        cancelDownloadButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value {
                    downloadService.cancelDownload(filename: downloadAssetIdentifier)
                }
            })
            .disposed(by: bag)

        downloadButtonTapEvent.asObservable()
            .subscribe(onNext: { currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value,
                    let downloadAssetRemoteUrlString: String = self.downloadAssetRemoteUrlString.value {
                    if let playableUuid: String = downloadAssetIdentifier.components(separatedBy: ".").first {
                        downloadService.fetchDownload(url: downloadAssetRemoteUrlString,
                                                      filename: downloadAssetIdentifier,
                                                      playableUuid: playableUuid)
                    }
                    

                }
            }, onError: { error in
                DDLogDebug("downloadButtonTapEvent error: \(error)")
            })
            .disposed(by: bag)
        
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
            .next { fileDownloadState in
                if fileDownloadState == .initial {
                    self.downloadNotStarted.value = true
                    self.downloadInProgress.value = false
                    self.completedDownload.value = false
                } else if fileDownloadState == .initiating {
                    self.downloadNotStarted.value = false
                    self.downloadStarting.value = true
                    self.downloadInProgress.value = false
                    self.completedDownload.value = false
                } else if fileDownloadState == .inProgress {
                    self.downloadNotStarted.value = false
                    self.downloadStarting.value = false
                    self.downloadInProgress.value = true
                    self.completedDownload.value = false
                } else if fileDownloadState == .complete {
                    self.downloadNotStarted.value = false
                    self.downloadStarting.value = false
                    self.downloadInProgress.value = false
                    self.completedDownload.value = true
                }
        }
        .disposed(by: bag)

    }

    @objc func handleUserDidTapCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        
        if let uuid: String = notification.object as? String {
            if let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value {
                if downloadAssetIdentifier.starts(with: uuid) {
                    downloadService.cancelDownload(filename: downloadAssetIdentifier)
                }
            }
        }
    }
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            self.downloadService.updateFileDownloadHistory(fileDownload: fileDownload)
                .asObservable()
                .subscribeAndDispose(by: bag)
        }

        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value {
            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAssetIdentifier {
                
                self.downloadState.onNext(.initiating)
            }
            
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            self.downloadService.updateFileDownloadHistory(fileDownload: fileDownload)
                .asObservable()
                .subscribeAndDispose(by: bag)
        }

        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value {
            DDLogDebug("downloadAssetIdentifier: \(downloadAssetIdentifier)")
            if fileDownload.localUrl.lastPathComponent == downloadAssetIdentifier {
                
//                self.downloadMaxValue.value = CGFloat(fileDownload.totalCount)
//                self.downloadValue.value = CGFloat(fileDownload.completedCount)
                
                self.downloadState.onNext(.inProgress)
                
                DDLogDebug("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
            }
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            self.downloadService.updateFileDownloadHistory(fileDownload: fileDownload)
                .asObservable()
                .subscribeAndDispose(by: bag)
        }
        
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAssetIdentifier: String = self.downloadAssetIdentifier.value {
            DDLogDebug("completeNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAssetIdentifier {
                
                self.downloadState.onNext(.complete)
//                self.completedDownload.value = true
            }
        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            self.downloadService.deleteFileDownloadHistory(playableUuid: fileDownload.playableUuid)
                .subscribe(onSuccess: {
                    self.downloadState.onNext(.initial)
                }) { error in
                    DDLogDebug("error deleting file download history: \(error)")
                }
                .disposed(by: bag)
        }

//        if let fileDownload: FileDownload = notification.object as? FileDownload,
//            let downloadAsset: Asset = self.downloadAsset.value {
//            DDLogDebug("errorNotification filedownload: \(fileDownload)")
//            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
//                // even though it's an error, just set it back to .initial
//                // because we have no use case for an errored download at the moment
//                self.downloadState.onNext(.initial)
//            }
//        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
//            self.downloadService.storeFileDownload(fileDownload: fileDownload, userUuid: "DB7F19C8-1A16-4D2F-8509-EDA538A3157B")
//                .asObservable()
//                .subscribeAndDispose(by: bag)
            
//             do not delete file here because the URLSession will generate an error
//             delete file in handleDownloadDidErrorNotification instead

            self.downloadService.deleteFileDownloadHistory(playableUuid: fileDownload.playableUuid)
                .subscribe(onSuccess: {
                    self.downloadState.onNext(.initial)
                }) { error in
                    DDLogDebug("error deleting file download history: \(error)")
            }
            .disposed(by: bag)

        }

//        if let fileDownload: FileDownload = notification.object as? FileDownload,
//            let downloadAsset: Asset = self.downloadAsset.value {
//            DDLogDebug("cancelNotification filedownload: \(fileDownload)")
//            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
//                self.downloadState.onNext(.initial)
//            }
//        }
    }
}

