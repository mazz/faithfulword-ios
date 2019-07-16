//
//  DownloadingViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-08.
//  Copyright © 2018 KJVRVG. All rights reserved.
//
import Foundation
import RxSwift

internal final class DownloadingViewModel {
    // MARK: Fields

    // MARK: from client
    // the asset that the user intends to download
    public var downloadAsset = Field<Asset?>(nil)
    // the tap event initiated by the user
    public var downloadButtonTapEvent = PublishSubject<FileDownloadState>()
    // the tap event initiated by the user
    public var cancelDownloadButtonTapEvent = PublishSubject<FileDownloadState>()
    
    // MARK: to client
    public var downloadState = PublishSubject<FileDownloadState>()
    
    public var downloadNotStarted = Field<Bool>(false)
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
        notificationCenter.addObserver(self, selector: #selector(DownloadingViewModel.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadingViewModel.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadingViewModel.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadingViewModel.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadingViewModel.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)
    }
    
    deinit {
        
    }

    private func setupBindings() {
        cancelDownloadButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAsset: Asset = self.downloadAsset.value {
//                    downloadService.removeDownload(filename: downloadAsset.uuid)
                    downloadService.cancelDownload(filename: downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")))
                        .asObservable()
                        .subscribeAndDispose(by: self.bag)
                }
            })
            .disposed(by: bag)

        downloadButtonTapEvent.asObservable()
            .subscribe(onNext: { currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let downloadService = self.downloadService,
                    let downloadAsset: Asset = self.downloadAsset.value {
                    DDLogDebug("downloadAsset.uuid: \(downloadAsset.uuid)")
                    downloadService.fetchDownload(url: downloadAsset.urlAsset.url.absoluteString, filename: downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")))
                        .asObservable()
                        .subscribeAndDispose(by: self.bag)
//                        .subscribe(onSuccess: {
//                            DDLogDebug("started download")
//                        }, onError: { error in
//                            DDLogDebug("download error: \(error)")
//                        })
                }
            }, onError: { error in
                DDLogDebug("downloadButtonTapEvent error: \(error)")
            })
            .disposed(by: bag)
        
        downloadAsset.asObservable()
            .filterNils()
            .subscribe(onNext: { asset in
                if FileManager.default.fileExists(atPath: FileSystem.savedDirectory.appendingPathComponent(asset.uuid.appending(String(describing: ".\(asset.fileExtension)"))).path) {
                    self.downloadState.onNext(.complete)
                    //            downloadImageNameEvent.value = "share-box"
                } else {
                    self.downloadState.onNext(.initial)
                    //            downloadImageNameEvent.value = "download_icon_black"
                }
            })
            .disposed(by: bag)
        
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
            .next { fileDownloadState in
                if fileDownloadState == .initial {
                    self.downloadNotStarted.value = true
                    self.downloadInProgress.value = false
                    self.completedDownload.value = false
                } else if fileDownloadState == .inProgress {
                    self.downloadNotStarted.value = false
                    self.downloadInProgress.value = true
                    self.completedDownload.value = false
                } else if fileDownloadState == .complete {
                    self.downloadNotStarted.value = false
                    self.downloadInProgress.value = false
                    self.completedDownload.value = true
                }
        }
    }

    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAsset: Asset = self.downloadAsset.value {
            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
                
                self.downloadState.onNext(.initiating)
            }
            
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAsset: Asset = self.downloadAsset.value {
            DDLogDebug("lastPathComponent: \(fileDownload.localUrl.lastPathComponent) uuid: \(downloadAsset.uuid)")
            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
                
//                self.downloadMaxValue.value = CGFloat(fileDownload.totalCount)
//                self.downloadValue.value = CGFloat(fileDownload.completedCount)
                
                self.downloadState.onNext(.inProgress)
                
                DDLogDebug("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
            }
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAsset: Asset = self.downloadAsset.value {
            DDLogDebug("completeNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
                self.downloadState.onNext(.complete)
//                self.completedDownload.value = true
            }
        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAsset: Asset = self.downloadAsset.value {
            DDLogDebug("errorNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
                // even though it's an error, just set it back to .initial
                // because we have no use case for an errored download at the moment
                self.downloadState.onNext(.initial)
            }
        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload,
            let downloadAsset: Asset = self.downloadAsset.value {
            DDLogDebug("cancelNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
                self.downloadState.onNext(.initial)
            }
        }
    }
}

