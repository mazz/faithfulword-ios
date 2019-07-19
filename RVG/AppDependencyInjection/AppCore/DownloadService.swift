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

protocol DownloadServicing {
    var operations: [String: DownloadOperation] { get }
    var fileDownloads: [String: FileDownload] { get }
    func fetchDownload(url: String, filename: String, playableUuid: String) -> Single<Void>
    func cancelDownload(filename: String) -> Single<Void>
}

public final class DownloadService: NSObject {
    static let fileDownloadDidInitiateNotification = Notification.Name("fileDownloadDidInitiateNotification")
    static let fileDownloadDidProgressNotification = Notification.Name("fileDownloadDidProgressNotification")
    static let fileDownloadDidCompleteNotification = Notification.Name("fileDownloadDidCompleteNotification")
    static let fileDownloadDidErrorNotification = Notification.Name("fileDownloadDidErrorNotification")
    static let fileDownloadDidCancelNotification = Notification.Name("fileDownloadDidCancelNotification")
    
    // MARK: Fields(
    private let bag = DisposeBag()
    //    private var queue: OperationQueue {
    //        let queue: OperationQueue = OperationQueue()
    //        queue.maxConcurrentOperationCount = 1
    //        return queue
    //    }
    
    public var operations: [String: DownloadOperation] = [:]
    public var fileDownloads: [String: FileDownload] = [:]
    
    // MARK: Dependencies
    private let reachability: RxClassicReachable
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private let downloadQueue: OperationQueue = {
        let _queue = OperationQueue()
        _queue.name = "DownloadServiceOperationQueue"
        _queue.maxConcurrentOperationCount = 1
        return _queue
    }()
    
    init(reachability: RxClassicReachable) {
        self.reachability = reachability
        super.init()
        
        reactToReachability()
    }
}

extension DownloadService: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let identifier: String = session.configuration.identifier {
//
//            // delete the file
//            let fullPath: URL = self.saveLocationUrl(identifier: identifier, removeExistingFile: true)
//        }
        DispatchQueue.main.async { [weak self] in
            if let identifier: String = session.configuration.identifier,
                let weakSelf = self,
                //            let url: URL = downloadTask.currentRequest?.url,
                let errorOperation: DownloadOperation = weakSelf.operations[identifier],
                let fileDownload: FileDownload = weakSelf.fileDownloads[identifier],
                let err = error {
                DDLogDebug("didCompleteWithError: session: \(String(describing: session)) task: \(task) error: \(String(describing: error))")

                //                weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: true)
                weakSelf.operations[identifier] = nil
                // pretty sure this deletes the file temp location
                errorOperation.cancel()
//                let download: FileDownload = FileDownload(url: fileDownload.url,
//                                                          localUrl: fileDownload.localUrl,
//                                                          progress: Float(fileDownload.totalCount)/Float(fileDownload.completedCount),
//                                                          totalCount: fileDownload.totalCount,
//                                                          completedCount: fileDownload.completedCount,
//                                                          state: .error)
                let download: FileDownload = FileDownload(url: fileDownload.url,
                                                          uuid: fileDownload.uuid,
                                                          playableUuid: fileDownload.playableUuid,
                                                          localUrl: fileDownload.localUrl, updatedAt: Date().timeIntervalSince1970,
                                                          insertedAt: fileDownload.insertedAt,
                                                          progress: Float(fileDownload.totalCount)/Float(fileDownload.completedCount),
                                                          totalCount: fileDownload.totalCount,
                                                          completedCount: fileDownload.completedCount,
                                                          state: .error)
                weakSelf.fileDownloads[identifier] = nil
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidErrorNotification, object: download)
            }
        }
        
    }
}

extension DownloadService: URLSessionDownloadDelegate {
    //    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    //        DDLogDebug("urlSessionDidFinishEvents: \(session)")
    //    }
    //
    //    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    //        DDLogDebug("didBecomeInvalidWithError: \(String(describing: error))")
    //    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DDLogDebug("didFinishDownloadingTo: session: \(String(describing: session)) downloadTask: \(downloadTask) location: \(location)")
        
        DDLogDebug("FileManager.default.fileExists location: \(location.path) \(FileManager.default.fileExists(atPath: location.path))")
        
        // need to save the file on non-main thread
        if let identifier: String = session.configuration.identifier {
            
            // if it is possible for the download to be interrupted(and no resume implemented)
            // the best policy is probably to delete the existing file at download initiation
            let fullPath: URL = self.saveLocationUrl(identifier: identifier, removeExistingFile: true)
            DDLogDebug("FileManager.default.fileExists non-main location: \(location.path) \(FileManager.default.fileExists(atPath: location.path))")
            
            self.writeFileToSavedDirectory(localSourceUrl: location, localDestinationUrl: fullPath)
            
        }
        
        DispatchQueue.main.async { [weak self] in
            DDLogDebug("FileManager.default.fileExists main location: \(location.path) \(FileManager.default.fileExists(atPath: location.path))")
            if let identifier: String = session.configuration.identifier,
                let weakSelf = self,
                //            let url: URL = downloadTask.currentRequest?.url,
                let finishingDownload: DownloadOperation = weakSelf.operations[identifier],
                let fileDownload: FileDownload = weakSelf.fileDownloads[identifier] {
                
                
                let fileDownload: FileDownload = FileDownload(url: fileDownload.url,
                                                              uuid: fileDownload.uuid,
                                                              playableUuid: fileDownload.playableUuid,
                             localUrl: fileDownload.localUrl,
                             updatedAt: Date().timeIntervalSince1970,
                             insertedAt: fileDownload.insertedAt,
                             progress: 1.0,
                             totalCount: fileDownload.totalCount,
                             completedCount: fileDownload.completedCount,
                             state: .complete)
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCompleteNotification, object: fileDownload)
                
                // pretty sure this deletes the file temp location
                finishingDownload.cancel()
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DDLogDebug("didWriteData: session: \(String(describing: session)) downloadTask: \(downloadTask) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        DispatchQueue.main.async { [weak self] in
            if let identifier: String = session.configuration.identifier,
                //                let url: URL = downloadTask.currentRequest?.url,
                let weakSelf = self,
                let download: FileDownload = weakSelf.fileDownloads[identifier] {
                
                let fileDownload: FileDownload = FileDownload(url: download.url,
                                                              uuid: download.uuid,
                                                              playableUuid: download.playableUuid,
                             localUrl: download.localUrl,
                             updatedAt: Date().timeIntervalSince1970,
                             insertedAt: download.insertedAt,
                             progress: Float(totalBytesWritten)/Float(totalBytesExpectedToWrite),
                             totalCount: totalBytesExpectedToWrite,
                             completedCount: totalBytesWritten,
                             state: .inProgress)

                weakSelf.fileDownloads[identifier] = fileDownload
                
                DDLogDebug("inflight operations count: \(weakSelf.downloadQueue.operations.count) operations: \(weakSelf.downloadQueue.operations)")
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidProgressNotification, object: fileDownload)
            }
        }
        
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DDLogDebug("didResumeAtOffset: session: \(String(describing: session)) downloadTask: \(downloadTask) fileOffset: \(fileOffset) expectedTotalBytes: \(expectedTotalBytes)")
    }
    
}

extension DownloadService: DownloadServicing {
    func fetchDownload(url: String, filename: String, playableUuid: String) -> Single<Void> {
        
        return Single.create { [weak self] single -> Disposable in
            
            let identifier: String = "app.fwsaved.downloadsession_\(filename)"
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
//            configuration.timeoutIntervalForResource = 5.0

            let sessionQueue = OperationQueue()
            let urlSession: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)
            
            if let remoteUrl = URL(string: url),
                let weakSelf = self {
                let operation = DownloadOperation(session: urlSession, downloadTaskURL: remoteUrl)
                
                weakSelf.downloadQueue.addOperation(operation)
                weakSelf.operations[identifier] = operation
                
                let fileDownload: FileDownload = FileDownload(url: remoteUrl,
                                                              uuid: NSUUID().uuidString,
                                                              playableUuid: playableUuid,
                                                              localUrl: weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                              updatedAt: Date().timeIntervalSince1970,
                                                              insertedAt: Date().timeIntervalSince1970,
                                                              progress: 0,
                                                              totalCount: 0,
                                                              completedCount: 0,
                                                              state: .initiating)
                weakSelf.fileDownloads[identifier] = fileDownload
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: DownloadService.fileDownloadDidInitiateNotification, object: fileDownload)
                }
                
                single(.success(()))
            } else {
                single(.error(FileDownloadError.downloadFailed("could not start download")))
            }
            return Disposables.create { }
        }
    }
    
    // cancelDownload will cancel the download and remove
    // the partial file and remove the filedownload from the map
    // and remove the download operation
    
    func cancelDownload(filename: String) -> Single<Void> {
        let identifier: String = "app.fwsaved.downloadsession_\(filename)"
        
        return Single.create { [weak self] single -> Disposable in
            if let weakSelf = self {
                weakSelf.cancelDownloadResources(for: identifier)
                single(.success(()))
            } else {
                single(.error(CancelDownloadError.cancelFailed("unknown")))
            }
            return Disposables.create { }
        }
    }
}

extension DownloadService {
    
    func cancelDownloadResources(for identifier: String) {
//        if let weakSelf = self,
        if let cancelOperation: DownloadOperation = self.operations[identifier],
            let download: FileDownload = self.fileDownloads[identifier] {
            
            // make a download for the cancel notification, then remove it from map
            let fileDownload: FileDownload = FileDownload(url: download.url,
                                                          uuid: download.uuid,
                                                          playableUuid: download.playableUuid,
                                                          localUrl: self.saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                          updatedAt: Date().timeIntervalSince1970,
                                                          insertedAt: download.insertedAt,
                                                          progress: download.progress,
                                                          totalCount: download.totalCount,
                                                          completedCount: download.completedCount,
                                                          state: .cancelled)
            // remove existing file
            self.saveLocationUrl(identifier: identifier, removeExistingFile: true)
            self.fileDownloads[identifier] = nil
            cancelOperation.cancel()
            self.operations[identifier] = nil
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCancelNotification, object: fileDownload)
            }
        }
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
    
    func writeFileToSavedDirectory(localSourceUrl: URL, localDestinationUrl: URL) {
        // capture the audio file as a Data blob and then write it
        // to temp dir
        
        do {
            let audioData: Data = try Data(contentsOf: localSourceUrl, options: .uncached)
            try audioData.write(to: localDestinationUrl, options: .atomicWrite)
        } catch {
            DDLogDebug("error writing audio file: \(error)")
            return
        }
        
        do {
            // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: localDestinationUrl.path)
        } catch {
            DDLogDebug("error while setting file permissions")
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

