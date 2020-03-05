//
//  DownloadListingViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-22.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import os.log

internal final class DownloadListingViewModel {
    // MARK: Fields
    
    // MARK: from client
    // the asset that the user intends to download
    //    public var downloadAsset = Field<Asset?>(nil)
    //<uuid>.mp3
//    public var downloadAssetIdentifier = Field<String?>(nil)
//    //https: //remoteurl.com/full/path.mp3
    public var fileDownloadDeleted = Field<String?>(nil)
    
    // every time a file download state changes from one of the notification
    // callbacks, it gets published with fileDownloadDirty. The view controller can observe
    // this and determine which collection view index path needs to be refreshed
    public var fileDownloadDirty: PublishSubject<FileDownload> = PublishSubject<FileDownload>()
    
    // every time a file download state changes to complete from one of the notification
    // callbacks, it gets published with fileDownloadDirtyComplete. The view controller can observe
    // this and determine which collection view index path needs to be refreshed
    public var fileDownloadDirtyComplete: PublishSubject<FileDownload> = PublishSubject<FileDownload>()

//
    public var downloadingItems: [String: FileDownload] = [:]
    public var downloadedItems: [String: FileDownload] = [:]
    public var downloadInterruptedItems: [String: FileDownload] = [:]
    public var storedDownloads: [String: FileDownload] = [:]

    
    
//    // the state of the download button image name
//    public let downloadImageNameEvent = Field<String>("download_icon_black")
    // MARK: Dependencies
    private let downloadService: DownloadServicing!
    private let bag = DisposeBag()
    
    internal init(downloadService: DownloadServicing) {
        self.downloadService = downloadService
        
        let notificationCenter = NotificationCenter.default
        
        // MediaItemCell
//        notificationCenter.addObserver(self, selector: #selector(MediaDetailsViewController.handleUserDidTapMoreNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(MediaDetailsViewController.handleUserDidTapCancelNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
        
        // DownloadService
        notificationCenter.addObserver(self, selector: #selector(DownloadListingViewModel.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadListingViewModel.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadListingViewModel.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadListingViewModel.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(DownloadListingViewModel.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)

    }
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidErrorNotification, object: nil)
    }


    public func storedFileDownload(for playableUuid: String) -> Single<FileDownload?> {
        return self.downloadService.fetchFileDownloadHistory(playableUuid: playableUuid)
    }
    
    public func storedFileDownloads(for playlistUuid: String) -> Single<[FileDownload]> {
        return self.downloadService.fetchStoredFileDownloads(for: playlistUuid)
    }

    public func storedFileDownloads() -> Single<[FileDownload]> {
        return self.downloadService.fetchStoredFileDownloads()
    }

    public func activeFileDownloads(_ playlistUuid: String) -> Single<[FileDownload]> {
        return self.downloadService.activeFileDownloads(playlistUuid)
    }

    public func activeFileDownloads() -> Single<[FileDownload]> {
        return self.downloadService.activeFileDownloads()
    }

    public func updateFileDownloadHistory(for fileDownload: FileDownload) {
        self.downloadService.updateFileDownloadHistory(fileDownload: fileDownload)
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func deleteFileDownload(for playableUuid: String, pathExtension: String) {
        
        // it may have been a partially downloaded file, so also remove it from downloadedItems
//        self.downloadedItems[playableUuid] = nil
//        self.downloadingItems[playableUuid] = nil
//        self.fileDownloadDeleted.value = playableUuid
        
        Observable.combineLatest(self.downloadService.deleteFileDownloadFile(playableUuid: playableUuid, pathExtension: pathExtension).asObservable(), self.downloadService.deleteFileDownloadHistory(playableUuid: playableUuid).asObservable())
            .next({ _ in
                os_log("deleteFileDownload deleted playableUuid: %{public}@", log: OSLog.data, String(describing: playableUuid))
                self.fileDownloadDeleted.value = playableUuid
            })
            .disposed(by: bag)
    }
    
    func fetchDownload(for playable: Playable, playlistUuid: String) {
        if let path: String = playable.path,
            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) {
            let fileIdentifier: String = playable.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
            
            downloadedItems[playable.uuid] = nil
            downloadService.fetchDownload(url: remoteUrl.absoluteString,
                                          filename: fileIdentifier,
                                          playableUuid: playable.uuid,
                                          playlistUuid: playlistUuid)
        }
    }

    func cancelDownload(for playable: Playable, playlistUuid: String) {
        if let path: String = playable.path,
            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) {
            let fileIdentifier: String = playable.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
            
            downloadService.cancelDownload(filename: fileIdentifier, playlistUuid: playlistUuid)
        }
    }
    
    // MARK: DownloadService notifications
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("DownloadListingViewModel initiateNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            os_log("DownloadListingViewModel lastPathComponent: %{public}@", log: OSLog.data, String(describing: fileDownload.localUrl.lastPathComponent))
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.updateFileDownloadHistory(for: fileDownload)
            
            fileDownloadDirty.onNext(fileDownload)
//            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
//            if indexPath.row != -1 {
//                lastProgressChangedUpdate.onNext(indexPath)
//            }
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("DownloadListingViewModel didProgressNotification fileDownload: %{public}@", log: OSLog.data, String(describing: fileDownload.localUrl.lastPathComponent))
            os_log("DownloadListingViewModel didProgressNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))

            downloadingItems[fileDownload.playableUuid] = fileDownload

            // it is possible it once was downloadInterruptedItems, so let's clobber it out
            if let _: FileDownload = downloadInterruptedItems[fileDownload.playableUuid] {
                downloadInterruptedItems[fileDownload.playableUuid] = nil
            }
            
            self.updateFileDownloadHistory(for: fileDownload)
            
            fileDownloadDirty.onNext(fileDownload)
//            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
//            if indexPath.row != -1 {
//                lastProgressChangedUpdate.onNext(indexPath)
//            }
            
            //            lastProgressChangedUpdate.onNext(Date())
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("DownloadListingViewModel completeNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            // store download as `downloaded`
            downloadedItems[fileDownload.playableUuid] = fileDownload
            
            self.updateFileDownloadHistory(for: fileDownload)
            

            fileDownloadDirtyComplete.onNext(fileDownload)
//            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
//            if indexPath.row != -1 {
//                lastDownloadCompleteUpdate.onNext(indexPath)
//            }
        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("DownloadListingViewModel errorNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
//            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            // when cloudfront cannot find a file, we see completedCount > totalCount
            // if completedCount > totalCount
            // we should:
            // show the error state in downloadedItems, this will show the error for this session only
            // delete the file
            // remove the item from downloadingItems
            // NOT record the download
            // else
            // assume the user cancelled the file and HWIDownload is reporting an error
            
            if fileDownload.completedCount > fileDownload.totalCount {
                
                self.deleteFileDownload(for: fileDownload.playableUuid, pathExtension: fileDownload.localUrl.lastPathComponent)
                self.fileDownloadDirty.onNext(fileDownload)
//                self.fileDownloadDeleted.value = fileDownload.playableUuid
                self.downloadingItems[fileDownload.playableUuid] = nil
                self.downloadedItems[fileDownload.playableUuid] = fileDownload

            } else { // user cancelled
                self.updateFileDownloadHistory(for: fileDownload)
                
                fileDownloadDirty.onNext(fileDownload)
            }
            
//            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
//            if indexPath.row != -1 {
//                lastProgressChangedUpdate.onNext(indexPath)
//            }
        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("DownloadListingViewModel cancelNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.updateFileDownloadHistory(for: fileDownload)

            fileDownloadDirty.onNext(fileDownload)

//            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
//            if indexPath.row != -1 {
//                lastProgressChangedUpdate.onNext(indexPath)
//            }
        }
    }

}

