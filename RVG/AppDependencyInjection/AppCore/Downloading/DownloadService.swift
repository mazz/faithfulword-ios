//
//  DownloadServicing.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import HWIFileDownload

protocol DownloadServicing {
//    var operations: [String: DownloadOperation] { get }
    var fileDownloads: [String: FileDownload] { get }
    var fileDownloadStateItems: [String: DownloadStateItem] { get }

    func fetchDownload(url: String, filename: String, playableUuid: String, playlistUuid: String?) // -> Single<Void>
    func cancelAllDownloads()
    func cancelDownload(filename: String, playlistUuid: String?) // -> Single<Void>
    func inProgressDownloads() -> [String]
    
    func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void>
    func fetchFileDownloadHistory(playableUuid: String) -> Single<FileDownload?>
    func deleteFileDownloadHistory(playableUuid: String) -> Single<Void>
    func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void>
    func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void>
    
    func fetchStoredFileDownloads(for playlistUuid: String) -> Single<[FileDownload]>
}

extension DownloadService: HWIFileDownloadDelegate {
    public func downloadDidComplete(withIdentifier identifier: String, localFileURL: URL) {
        DDLogDebug("downloadDidComplete: \(String(describing: identifier)) localFileURL: \(String(describing: localFileURL))")
        //        if let stateItem: DownloadStateItem = self.fileDownloadStateItems[identifier],
        if let fileDownload: FileDownload = self.fileDownloads[identifier] {
            
            // need to save the file on non-main thread
            
            // if it is possible for the download to be interrupted(and no resume implemented)
            // the best policy is probably to delete the existing file at download initiation
            let fullPath: URL = self.saveLocationUrl(identifier: identifier, removeExistingFile: true)
            self.writeFileToSavedDirectory(localSourceUrl: localFileURL, localDestinationUrl: fullPath, deleteSource: true)
            self.decrementNetworkActivityIndicatorActivityCount()
            
            DispatchQueue.main.async {
                var download: FileDownload = FileDownload(url: fileDownload.url,
                                                              uuid: fileDownload.uuid,
                                                              playableUuid: fileDownload.playableUuid,
                                                              localUrl: fileDownload.localUrl,
                                                              updatedAt: Date().timeIntervalSince1970,
                                                              insertedAt: fileDownload.insertedAt,
                                                              progress: 1.0,
                                                              totalCount: fileDownload.totalCount,
                                                              completedCount: fileDownload.completedCount,
                                                              state: .complete)
                
                download.playlistUuid = fileDownload.playlistUuid
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCompleteNotification, object: download)
            }
        }
        
    }
    
    // optional
    
    
//    2019-07-26 20:58:37:479 Faithful Word[24948:4774270] downloadProgressChanged stateItem: Optional({
//    bytesPerSecondSpeed = 2956083;
//    downloadProgress = "0.8388826";
//    estimatedRemainingTime = "0.05412566661834717";
//    expectedFileSize = 993065;
//    lastLocalizedAdditionalDescription = "833 KB of 993 KB \U2014 About 0 seconds remaining";
//    lastLocalizedDescription = "Processing files\U2026";
//    nativeProgress = "<NSProgress: 0x600000b4e940> : Parent: 0x0 / Fraction completed: 0.8389 / Completed: 833065 of 993065  ";
//    receivedFileSize = 833065;
//    })

    public func downloadProgressChanged(forIdentifier identifier: String) {
        // self.fileDownloads[identifier]
        
        if let stateItem: DownloadStateItem = self.fileDownloadStateItems[identifier],
            let fileDownload: FileDownload = self.fileDownloads[identifier],
            let fileDownloader: HWIFileDownloader = self.fileDownloader,
            let downloadProgress: HWIFileDownloadProgress = fileDownloader.downloadProgress(forIdentifier: identifier) {
            
            stateItem.progress = downloadProgress
            stateItem.progress?.lastLocalizedDescription = stateItem.progress?.nativeProgress.localizedDescription
            stateItem.progress?.lastLocalizedAdditionalDescription = stateItem.progress?.nativeProgress.localizedAdditionalDescription
            // create a new FileDownload, store it/update it and post it
            
            DispatchQueue.main.async { [weak self] in
                
                
                    if let weakSelf = self,
                        let hwiProgress: HWIFileDownloadProgress = stateItem.progress {
                        // we have not cancelled, so we will send a progress update
                        // this check is necessary because there is a delay from when the
                        // user taps cancel and when download actually stops receiving bytes
                        // the result would be that even after the user taps cancel, the
                        // progress UI continues, resulting in a subpar user experience
                        if stateItem.cancelImmediately == false {
                            var download: FileDownload = FileDownload(url: fileDownload.url,
                                                                      uuid: fileDownload.uuid,
                                                                      playableUuid: fileDownload.playableUuid,
                                                                      localUrl: fileDownload.localUrl,
                                                                      updatedAt: Date().timeIntervalSince1970,
                                                                      insertedAt: fileDownload.insertedAt,
                                                                      progress: hwiProgress.downloadProgress,
                                                                      totalCount: hwiProgress.expectedFileSize,
                                                                      completedCount: hwiProgress.receivedFileSize,
                                                                      state: .inProgress)
                            
                            download.extendedDescription = stateItem.progress?.nativeProgress.localizedAdditionalDescription
                            download.playlistUuid = fileDownload.playlistUuid
                            
                            weakSelf.fileDownloads[identifier] = download
                            NotificationCenter.default.post(name: DownloadService.fileDownloadDidProgressNotification, object: download)
                        } else {
                            DDLogDebug("stateItem.cancelImmediately: \(String(describing: stateItem.cancelImmediately))")
                        }
                    }
            }
        }
    }

    public func downloadFailed(withIdentifier identifier: String, error: Error, httpStatusCode: Int, errorMessagesStack: [String]?, resumeData: Data?) {
        DDLogDebug("downloadFailed: \(String(describing: identifier)) error: \(error) httpStatusCode: \(httpStatusCode) errorMessagesStack:\(errorMessagesStack ?? [""])")
        
//        if let stateItem: DownloadStateItem = self.fileDownloadStateItems[identifier],
        if let fileDownload: FileDownload = self.fileDownloads[identifier] {
//            let fileDownloader: HWIFileDownloader = self.fileDownloader,
//            let downloadProgress: HWIFileDownloadProgress = fileDownloader.downloadProgress(forIdentifier: identifier) {

            DispatchQueue.main.async { [weak self] in
                if let weakSelf = self {
//                    let hwiProgress: HWIFileDownloadProgress = stateItem.progress {

//                    stateItem.progress = downloadProgress
//                    stateItem.progress?.lastLocalizedDescription = stateItem.progress?.nativeProgress.localizedDescription
//                    stateItem.progress?.lastLocalizedAdditionalDescription = stateItem.progress?.nativeProgress.localizedAdditionalDescription

                    var download: FileDownload = FileDownload(url: fileDownload.url,
                                                              uuid: fileDownload.uuid,
                                                              playableUuid: fileDownload.playableUuid,
                                                              localUrl: fileDownload.localUrl,
                                                              updatedAt: Date().timeIntervalSince1970,
                                                              insertedAt: fileDownload.insertedAt,
                                                              progress: Float(fileDownload.completedCount)/Float(fileDownload.totalCount),
                                                              totalCount: fileDownload.totalCount,
                                                              completedCount: fileDownload.completedCount,
                                                              state: .error)//,
//                                                              userUuid: "DB7F19C8-1A16-4D2F-8509-EDA538A3157B")
                    download.playlistUuid = fileDownload.playlistUuid
//                    download.extendedDescription = stateItem.progress?.nativeProgress.localizedAdditionalDescription

                    NotificationCenter.default.post(name: DownloadService.fileDownloadDidErrorNotification, object: download)
                    weakSelf.removeDownloadResources(for: identifier)
                    weakSelf.decrementNetworkActivityIndicatorActivityCount()
                }
            }
            
            
            
        }
        
    }
    
    public func onAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, downloadIdentifier: String, completionHandler: @escaping (URLCredential?, URLSession.AuthChallengeDisposition) -> Void) {
        completionHandler(nil, URLSession.AuthChallengeDisposition.performDefaultHandling)

//        DDLogDebug("onAuthenticationChallenge: \(String(describing: challenge.error)) failureResponse: \(String(describing: challenge.failureResponse))  downloadIdentifier: \(downloadIdentifier)")
//
//        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//            if let secTrust = challenge.protectionSpace.serverTrust {
//                var credential: URLCredential = URLCredential(trust: secTrust)
////                completionHandler(credential, URLSession.AuthChallengeDisposition.performDefaultHandling)
////                completionHandler(credential, URLSession.AuthChallengeDisposition.useCredential)
//                completionHandler(nil, URLSession.AuthChallengeDisposition.performDefaultHandling)
//            }
//        }
    }
    
}

public final class DownloadService: NSObject {
    
    static let fileDownloadDidInitiateNotification = Notification.Name("fileDownloadDidInitiateNotification")
    static let fileDownloadDidProgressNotification = Notification.Name("fileDownloadDidProgressNotification")
    static let fileDownloadDidCompleteNotification = Notification.Name("fileDownloadDidCompleteNotification")
    static let fileDownloadDidErrorNotification = Notification.Name("fileDownloadDidErrorNotification")
    static let fileDownloadDidCancelNotification = Notification.Name("fileDownloadDidCancelNotification")
    
    // MARK: Fields
    private let bag = DisposeBag()

    
//    public var operations: [String: DownloadOperation] = [:]
    public var fileDownloads: [String: FileDownload] = [:]
    public var fileDownloadStateItems: [String: DownloadStateItem] = [:]

    // MARK: Dependencies
    private let reachability: RxClassicReachable
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    private let dataService: FileDownloadDataServicing

    var fileDownloader: HWIFileDownloader? = nil
    var networkActivityIndicatorCount: UInt = 0
    
    init(reachability: RxClassicReachable,
         dataService: FileDownloadDataServicing) {
        self.reachability = reachability
        self.dataService = dataService
        super.init()
        
        reactToReachability()
    }
}

extension DownloadService: DownloadServicing {
    
    public func incrementNetworkActivityIndicatorActivityCount() {
        self.toggleNetworkActivityIndicatorVisible(visible: true)
    }
    
    public func decrementNetworkActivityIndicatorActivityCount() {
        self.toggleNetworkActivityIndicatorVisible(visible: false)
    }
    
    func toggleNetworkActivityIndicatorVisible(visible: Bool) {
        if (visible == true) {
            networkActivityIndicatorCount = networkActivityIndicatorCount + 1
        } else {
            networkActivityIndicatorCount = networkActivityIndicatorCount - 1
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = (networkActivityIndicatorCount > 0)
    }
    
    // MARK: download service
    
    func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void> {
        return self.dataService.updateFileDownloadHistory(fileDownload: fileDownload)
    }
    
    func fetchFileDownloadHistory(playableUuid: String) -> Single<FileDownload?> {
        return self.dataService.fetchLastFileDownloadHistory(playableUuid: playableUuid)
    }
    
    func deleteFileDownloadHistory(playableUuid: String) -> Single<Void> {
        return self.dataService.deleteLastFileDownloadHistory(playableUuid: playableUuid)
    }

    func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void> {
        return self.dataService.deleteFileDownloadFile(playableUuid: playableUuid, pathExtension: pathExtension)
    }

    func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void> {
        return self.dataService.updateFileDownloads(playableUuids: playableUuids, to: state)
    }

    // MARK: download list service
    
    func fetchStoredFileDownloads(for playlistUuid: String) -> Single<[FileDownload]> {
        return self.dataService.fileDownloads(for: playlistUuid)
    }
    
    
    // tell the download service to stop recording inProgress state
    // in local db to all fileDownloads. this is to fix the situation
    // where downloads interrupted by an app termination would report
    // an incorrect inProgress state in the sqlite db
    
    func cancelAllDownloads() {
        // use .initial because .cancelled results in a bad UI state for fullDownloadProgressButton
        updateFileDownloads(playableUuids: inProgressDownloads(), to: .initial)
            .asObservable()
            .subscribeAndDispose(by: bag)
    }
    

    
    func fetchDownload(url: String, filename: String, playableUuid: String, playlistUuid: String? = nil) { // -> Single<Void> {
        
        if self.fileDownloader == nil {
            self.fileDownloader = HWIFileDownloader(delegate: self, maxConcurrentDownloads: 3)
        }

        let identifier: String = "app.fwsaved.filedownload_\(filename)"

        if let remoteUrl = URL(string: url) {
            var fileDownload: FileDownload = FileDownload(url: remoteUrl,
                                                          uuid: NSUUID().uuidString,
                                                          playableUuid: playableUuid,
                                                          localUrl: saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                          updatedAt: Date().timeIntervalSince1970,
                                                          insertedAt: Date().timeIntervalSince1970,
                                                          progress: 0,
                                                          totalCount: 0,
                                                          completedCount: 0,
                                                          state: .initiating)//,
//                                                          userUuid: userUuid)
            fileDownload.playlistUuid = playlistUuid
            fileDownloads[identifier] = fileDownload
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidInitiateNotification, object: fileDownload)
            }

            // do download via HWIDownload
            let downloadItem: DownloadStateItem = DownloadStateItem(downloadIdentifier: identifier,
                                                                    remoteUrl: remoteUrl)
            
            self.fileDownloadStateItems[identifier] = downloadItem
            self.fileDownloader?.startDownload(withIdentifier: downloadItem.downloadIdentifier,
                                               fromRemoteURL: downloadItem.remoteUrl)
            
            self.incrementNetworkActivityIndicatorActivityCount()
        }
    }
    
    // cancelDownload will cancel the download and remove
    // the partial file and remove the filedownload from the map
    // and remove the download operation
    
    func cancelDownload(filename: String, playlistUuid: String?) { // -> Single<Void> {
        let identifier: String = "app.fwsaved.filedownload_\(filename)"
        DispatchQueue.main.async {
            
            //        return Single.create { [weak self] single -> Disposable in
            
            // post the cancelled download and then remove
            // system resources related to download
            
            //            if let weakSelf = self,
            if let download: FileDownload = self.fileDownloads[identifier],
                let stateItem: DownloadStateItem = self.fileDownloadStateItems[identifier] {
                
                //                self.fileDownloader
                
                stateItem.cancelImmediately = true

                self.fileDownloader?.cancelDownload(withIdentifier: identifier)
                
                var fileDownload: FileDownload = FileDownload(url: download.url,
                                                              uuid: download.uuid,
                                                              playableUuid: download.playableUuid,
                                                              localUrl: self.saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                              updatedAt: Date().timeIntervalSince1970,
                                                              insertedAt: download.insertedAt,
                                                              progress: download.progress,
                                                              totalCount: download.totalCount,
                                                              completedCount: download.completedCount,
                                                              state: .cancelled)//,
                //                                                          userUuid: download.userUuid)
                
                fileDownload.playlistUuid = playlistUuid

                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCancelNotification, object: fileDownload)
                
                self.removeDownloadResources(for: identifier)
                //                single(.success(()))
                //            } else {
                //                single(.error(CancelDownloadError.cancelFailed("unknown")))
                //            }
                //            return Disposables.create { }
            }
            
        }
    }
    
    func inProgressDownloads() -> [String] {
        var inProgressUuids: [String] = []

        for (_, download) in fileDownloads {
            if download.state == .inProgress {
                inProgressUuids.append(download.playableUuid)
            }
        }

        return inProgressUuids
    }
}

extension DownloadService {
    func removeDownloadResources(for identifier: String) {
        // remove existing file
        self.saveLocationUrl(identifier: identifier, removeExistingFile: true)
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown:
                    DDLogDebug("DownloadService \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("DownloadService \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("DownloadService \(self.reachability.status.value)")
                }
            }).disposed(by: bag)
    }
    
    func writeFileToSavedDirectory(localSourceUrl: URL, localDestinationUrl: URL, deleteSource: Bool) {
        // capture the audio file as a Data blob and then write it
        // to temp dir
        
        let fileManager = FileManager.default

        do {
            let audioData: Data = try Data(contentsOf: localSourceUrl, options: .uncached)
            try audioData.write(to: localDestinationUrl, options: .atomicWrite)
        } catch {
            DDLogDebug("error writing audio file: \(error)")
            return
        }
        
        do {
            // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
            try fileManager.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: localDestinationUrl.path)
        } catch {
            DDLogDebug("error while setting file permissions")
        }
        
        if deleteSource {
            do {
                try fileManager.removeItem(at: localSourceUrl)
            }
            catch let error {
                print("Ooops! Something went wrong removing file: \(error)")
            }
        }

    }
    
    func saveLocationUrl(identifier: String, removeExistingFile: Bool) -> URL {
        let components = identifier.split(separator:"_")
        let targetFilename: String = String(components[1])
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url: URL = urls[urls.endIndex - 1]
        
        let directory: URL = url.appendingPathComponent("Saved/")
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogDebug("error while creating directory")
        }
        
        let fullPath: URL = directory.appendingPathComponent(targetFilename)
        
        if removeExistingFile {
            do {
                try fileManager.removeItem(atPath: fullPath.path)
            }
            catch let error {
                print("Ooops! Something went wrong removing file: \(error)")
            }
        }
        
        DDLogDebug("fullPath: \(fullPath)")
        
        return fullPath
    }
}

class FileSystem {
    static let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    static let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    static let savedDirectory: URL = {
        let directory: URL = FileSystem.documentsDirectory.appendingPathComponent("Saved/")
        return directory
    }()
    
}

