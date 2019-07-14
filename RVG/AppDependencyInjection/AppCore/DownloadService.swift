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
    //    var progress: Observable<Float> { get }
    //    var state: Observable<FileDownloadState> { get }
    //    var fileDownload: Observable<FileDownload> { get }
    var downloadMap: [String: DownloadDataService] { get }
    var operations: [String: DownloadOperation] { get }
    var fileDownloads: [String: FileDownload] { get }
    func fetchDownload(url: String, filename: String) -> Single<Void>
    //    func activeDownload(filename: String) -> Observable<FileDownload>
    func cancelDownload(filename: String) -> Single<Void>
    func removeDownload(filename: String) -> Single<Void>
    func deleteDownloadService(filename: String) -> Single<Void>
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
    
    public var downloadMap: [String: DownloadDataService] = [:]
    public var operations: [String: DownloadOperation] = [:]
    public var fileDownloads: [String: FileDownload] = [:]
    
    
    //    public private(set) var media = Field<[Playable]>([])
    //    public var progress: Observable<Float> {
    //        return downloadDataService.progress
    //    }
    
    //    public var fileDownload: Observable<FileDownload> {
    //        return downloadDataService.fileDownload
    //    }
    
    //    public var state: Observable<FileDownloadState> {
    //        return downloadDataService.state
    //    }
    
    // MARK: Dependencies
    //    private var downloadQueue: OperationQueue
    
    private let downloadQueue: OperationQueue = {
        let _queue = OperationQueue()
        _queue.name = "DownloadServiceOperationQueue"
        _queue.maxConcurrentOperationCount = 1
        return _queue
    }()
    
    //    public init(downloadQueue: OperationQueue) {
    //        self.downloadQueue = downloadQueue
    //        self.downloadQueue.maxConcurrentOperationCount = 1
    //    }
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
            //            let weakSelf = self,
            //            let url: URL = downloadTask.currentRequest?.url,
            //            let finishingDownload: DownloadOperation = self.operations[identifier],
            //            let fileDownload: FileDownload = self.fileDownloads[identifier] {
            //            let fileDownload: FileDownload = FileDownload(url: fileDownload.url,
            //                                                          localUrl: fileDownload.localUrl,
            //                                                          progress: 1.0,
            //                                                          totalCount: fileDownload.completedCount,
            //                                                          completedCount: fileDownload.completedCount,
            //                                                          state: .complete)
            
            let fullPath: URL = self.saveLocationUrl(identifier: identifier, removeExistingFile: false)
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
                
                //        if let identifier: String = session.configuration.identifier {
                //            let fileDownload: FileDownload = self.fileDownloads[identifier] {
                
                //            var download = fileDownload
                //            download.state = .complete
                //            // refresh mapped download
                //            self.fileDownloads[identifier] = download
                
                let fileDownload: FileDownload = FileDownload(url: fileDownload.url,
                                                              localUrl: fileDownload.localUrl,
                                                              progress: 1.0,
                                                              totalCount: fileDownload.completedCount,
                                                              completedCount: fileDownload.completedCount,
                                                              state: .complete)
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCompleteNotification, object: fileDownload)
                
                //                let fullPath: URL = weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: false)
                //                DDLogDebug("FileManager.default.fileExists at write time location: \(location.path) \(FileManager.default.fileExists(atPath: location.path))")
                //
                //                weakSelf.writeFileToSavedDirectory(localSourceUrl: location, localDestinationUrl: fullPath)
                
                // pretty sure this deletes the file temp location
                finishingDownload.cancel()
                
                //                DDLogDebug("fullPath: \(fullPath)")
                //
                //                // capture the audio file as a Data blob and then write it
                //                // to temp dir
                //
                //                do {
                //                    let audioData: Data = try Data(contentsOf: location, options: .uncached)
                //                    try audioData.write(to: fullPath, options: .atomicWrite)
                //                } catch {
                //                    DDLogDebug("error writing audio file: \(error)")
                //                    return
                //                }
                //
                //                do {
                //                    // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
                //                    try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: fullPath.path)
                //                } catch {
                //                    DDLogDebug("error while setting file permissions")
                //                }
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
                //                let fileDownload: FileDownload = weakSelf.fileDownloads[identifier] {
                //                var download = fileDownload
                //                download.completedCount = totalBytesWritten
                //                download.totalCount = totalBytesExpectedToWrite
                //                download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
                //                download.state = .inProgress
                
                // refresh mapped download
                //                weakSelf.fileDownloads[identifier] = download
                
                let fileDownload: FileDownload = FileDownload(url: download.url,
                                                              localUrl: download.localUrl,
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
    func fetchDownload(url: String, filename: String) -> Single<Void> {
        
        return Single.create { [weak self] single -> Disposable in
            
            let identifier: String = "app.fwsaved.downloadsession_\(filename)"
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
            let sessionQueue = OperationQueue()
            let urlSession: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)
            
            if let remoteUrl = URL(string: url),
                let weakSelf = self {
                let operation = DownloadOperation(session: urlSession, downloadTaskURL: remoteUrl)
                
                weakSelf.downloadQueue.addOperation(operation)
                weakSelf.operations[identifier] = operation
                
                let fileDownload: FileDownload = FileDownload(url: remoteUrl,
                                                              localUrl: weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                              progress: 0,
                                                              totalCount: 0,
                                                              completedCount: 0,
                                                              state: .initiating)
                weakSelf.fileDownloads[identifier] = fileDownload
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidInitiateNotification, object: fileDownload)
                single(.success(()))
            } else {
                single(.error(FileDownloadError.downloadFailed("could not start download")))
            }
            return Disposables.create { }
        }
        //        let downloadDataService: DownloadDataService = DownloadDataService(fileWebService: MoyaProvider<FileWebService>())
        //        downloadMap[filename] = downloadDataService
        //        if let service = downloadMap[filename] {
        //            return service.downloadFile(url: url, filename: filename)
        //        } else { return Single.just(()) }
    }
    
    //    func activeDownload(filename: String) -> Observable<FileDownload> {
    //        var result: Observable<FileDownload>!
    //        if let service = downloadMap[filename] {
    //            result = service.fileDownload
    //        } else {
    //            result = Observable.error(FileDownloadError.missingDownload("no download for filename: \(filename)"))
    //        }
    //
    //        return result
    //    }
    
    // cancelDownload will cancel the download and remove
    // the partial file and remove the filedownload from the map
    // and remove the download operation
    
    func cancelDownload(filename: String) -> Single<Void> {
        let identifier: String = "app.fwsaved.downloadsession_\(filename)"
        
        return Single.create { [weak self] single -> Disposable in
            
            if let weakSelf = self,
                let cancelOperation: DownloadOperation = weakSelf.operations[identifier],
                let download: FileDownload = weakSelf.fileDownloads[identifier] {
                
                // make a download for the cancel notification, then remove it from map
                let fileDownload: FileDownload = FileDownload(url: download.url,
                                                              localUrl: weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: false),
                                                              progress: download.progress,
                                                              totalCount: download.totalCount,
                                                              completedCount: download.completedCount,
                                                              state: .cancelled)
                // remove existing file
                weakSelf.saveLocationUrl(identifier: identifier, removeExistingFile: true)
                weakSelf.fileDownloads[identifier] = nil
                cancelOperation.cancel()
                
                NotificationCenter.default.post(name: DownloadService.fileDownloadDidCancelNotification, object: fileDownload)
                single(.success(()))
            } else {
                single(.error(CancelDownloadError.cancelFailed("unknown")))
            }
            return Disposables.create { }
        }
    }
    
    // removeDownload will cancel the download, remove the partially downloaded
    // file and remove it from the downloadMap
    func removeDownload(filename: String) -> Single<Void> {
        if let downloadDataService = downloadMap[filename] {
            return downloadDataService.cancel()
                .flatMap { downloadDataService.deleteDownload() }
                .flatMap { self.deleteDownloadService(filename: filename) }
        } else {
            return Single.error(FileDownloadError.missingDownload("download could not be removed"))
        }
        //        if downloadMap[filename] != nil {
        //            downloadMap[filename] = nil
        //
        //            //            downloadDataService.deleteDownload
        //        } else {
        //            result = Single.error(FileDownloadError.missingDownload("download could not be removed"))
        //        }
        //        return result
    }
    
    func deleteDownloadService(filename: String) -> Single<Void> {
        return Single.create { [unowned self] single -> Disposable in
            if self.downloadMap[filename] != nil {
                self.downloadMap[filename] = nil
                single(.success(()))
            } else {
                single(.error(FileDownloadError.missingDownload("download could not be removed")))
            }
            return Disposables.create { }
        }
    }
}

extension DownloadService {
    
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
        
        // capture the audio file as a Data blob and then write it
        // to temp dir
        
        //        do {
        //            let audioData: Data = try Data(contentsOf: location, options: .uncached)
        //            try audioData.write(to: fullPath, options: .atomicWrite)
        //        } catch {
        //            DDLogDebug("error writing audio file: \(error)")
        //            return
        //        }
        //
        //        do {
        //            // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
        //            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: fullPath.path)
        //        } catch {
        //            DDLogDebug("error while setting file permissions")
        //        }
    }
}

