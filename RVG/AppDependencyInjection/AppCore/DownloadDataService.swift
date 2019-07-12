//
//  DownloadDataService.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import Moya
import RxSwift

public final class FileDownload {
    // MARK: Fields
    public let url: URL
    public let localUrl: URL
    public var progress: Float
    public var totalCount: Int64
    public var completedCount: Int64
    public var state: FileDownloadState

    public init(url: URL,
                localUrl: URL,
                progress: Float,
                totalCount: Int64,
                completedCount: Int64,
                state: FileDownloadState) {
        self.url = url
        self.localUrl = localUrl
        self.progress = progress
        self.totalCount = totalCount
        self.completedCount = completedCount
        self.state = state
    }
}

public enum FileDownloadState {
    case initial
    case initiating
    case inProgress
    case cancelling
    case cancelled
    case complete
    case error
    case unknown
}

public enum FileDownloadError: Error {
    case internalFailure(Error?)
    case downloadFailed(String)
    case missingDownload(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .internalFailure(let error):
            return "Internal file downloading error: \(String(describing: error))"
        case .downloadFailed(let reason):
            return "Download failed due to \(reason)"
        case .unknown:
            return "Download failed, reason unknown"
        case .missingDownload:
            return "download not found"
        }
    }
}

enum CancelDownloadError: Error {
    case cancelFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .cancelFailed(let reason):
            return "cancel failed due to \(reason)"
        case .unknown:
            return "Download cancel failed, reason unknown"
        }
    }
}

enum DeleteFileError: Error {
    case deleteFileFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .deleteFileFailed(let reason):
            return "file deletion failed due to \(reason)"
        case .unknown:
            return "file deletion failed, reason unknown"
        }
    }
}

public protocol FileDownloadDataServicing {
    var state: Observable<FileDownloadState> { get }
//    var progress: Observable<Float> { get }
    var fileDownload: Observable<FileDownload> { get }
    func downloadFile(url: String, filename: String) -> Single<Void>
    func deleteDownload() -> Single<Void>
}

public final class DownloadDataService {

    
    // MARK: Fields
//    private var stateSubject = BehaviorSubject<FileDownloadState>(value: .initial)
//    private var progressSubject: PublishSubject = PublishSubject<Float>()
    private var fileDownloadSubject: PublishSubject = PublishSubject<FileDownload>()
    private let fileWebService: MoyaProvider<FileWebService>!

    // the current download request
    private var internalRequest: Cancellable?
    // the current file download
    private var internalFileDownload: FileDownload?

    public init(fileWebService: MoyaProvider<FileWebService>) {
        self.fileWebService = fileWebService
    }
}


extension DownloadDataService: FileDownloadDataServicing {
    // MARK: Private Helpers

    // MARK: Public API

    public var state: Observable<FileDownloadState> {
        if let internalFileDownload = self.internalFileDownload {
            return Observable.just(internalFileDownload.state)
        } else {
            return Observable.just(.unknown)
        }
    }

    public var fileDownload: Observable<FileDownload> {
        return fileDownloadSubject.asObservable()
    }


    public func cancel() -> Single<Void> {
        return Single.create { [unowned self] single -> Disposable in
            if let internalFileDownload = self.internalFileDownload {
                switch internalFileDownload.state {
                case .initial, .cancelling, .cancelled, .complete:
                    single(.error(CancelDownloadError.cancelFailed("not in a cancellable state")))
                case .initiating, .inProgress, .error, .unknown:
                    if let internalRequest = self.internalRequest,
                        let internalFileDownload = self.internalFileDownload {
                        internalRequest.cancel()
                        internalFileDownload.state = .cancelled
                        self.fileDownloadSubject.onNext(internalFileDownload)
                        NotificationCenter.default.post(name: DownloadService.fileDownloadDidCancelNotification, object: internalFileDownload)
                        single(.success(()))
                    }
                }
            } else {
                single(.error(CancelDownloadError.cancelFailed("not in a cancellable state")))
            }
            return Disposables.create { }
        }
    }

    public func downloadFile(url: String, filename: String) -> Single<Void> {
        DDLogDebug("downloadFile url: \(url)")

//        self.stateSubject.onNext(.initiating)

        let fileService: FileWebService = FileWebService.download(url: url, filename: filename, fileExtension: nil)
        let downloadLocation: URL = fileService.downloadLocation
        if let remoteUrl = URL(string: url) {
            self.internalFileDownload = FileDownload(url: remoteUrl,
                                                     localUrl: downloadLocation,
                                                     progress: Float(0),
                                                     totalCount: Int64(0),
                                                     completedCount: Int64(0),
                                                     state: .initiating)
        } else { return Single.error(FileDownloadError.downloadFailed("could not create remoteUrl")) }

        if let internalFileDownload = self.internalFileDownload {
            // .initiating
            self.fileDownloadSubject.onNext(internalFileDownload)
            NotificationCenter.default.post(name: DownloadService.fileDownloadDidInitiateNotification, object: internalFileDownload)
        }

        self.internalRequest = fileWebService.request(fileService, callbackQueue: nil, progress: { progressResponse in

            if let totalUnitCount = progressResponse.progressObject?.totalUnitCount,
                let completedUnitCount = progressResponse.progressObject?.completedUnitCount {

                    if let internalFileDownload = self.internalFileDownload {
                        internalFileDownload.progress = Float(progressResponse.progress)
                        internalFileDownload.totalCount = totalUnitCount
                        internalFileDownload.completedCount = completedUnitCount

                        if Float(progressResponse.progress) >= 0.0 && Float(progressResponse.progress) < 1.0 {
                            if let internalFileDownload = self.internalFileDownload {
                                internalFileDownload.state = .inProgress
                                self.fileDownloadSubject.onNext(internalFileDownload)
                                DDLogDebug("internalFileDownload.localUrl: \(internalFileDownload.localUrl)")
                                // FIXME: it is possible to send at least one .inProgress
                                // notification even after the file download has been cancelled
                                NotificationCenter.default.post(name: DownloadService.fileDownloadDidProgressNotification, object: internalFileDownload)
                            }
                        }
                    }
//                }

            }
            DDLogDebug("progressResponse response statusCode: \(progressResponse.response?.statusCode)")
            DDLogDebug("progressResponse: \(progressResponse.progress)")
        }) { result in
            DDLogDebug("result: \(result)")
            switch result {
            case let .success(response):
                let statusCode = response.statusCode
                if let dataString: String = String(data: response.data, encoding: .utf8) {
                    DDLogDebug(".success: \(dataString)")
                    DDLogDebug(".success statusCode: \(statusCode)")
                    if let internalFileDownload = self.internalFileDownload {
                        if statusCode >= Int(200) && statusCode < 400 {
                            internalFileDownload.state = .complete
                            self.fileDownloadSubject.onNext(internalFileDownload)
                            NotificationCenter.default.post(name: DownloadService.fileDownloadDidCompleteNotification, object: internalFileDownload)
                            do {
                                // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
                                try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: internalFileDownload.localUrl.path)
                            } catch {
                                DDLogDebug("error while setting file permissions")
                            }

                            //                        self.stateSubject.onNext(.complete)
                        }
                        else if statusCode >= Int(400) {
                            internalFileDownload.state = .error
                            self.fileDownloadSubject.onNext(internalFileDownload)
                            NotificationCenter.default.post(name: DownloadService.fileDownloadDidErrorNotification, object: internalFileDownload)
                        }
                    }
                }
            case .failure(_):
                if let error = result.error {
                    if let internalFileDownload = self.internalFileDownload {
                        internalFileDownload.state = .error

                        self.fileDownloadSubject.onNext(internalFileDownload)
                        NotificationCenter.default.post(name: DownloadService.fileDownloadDidErrorNotification, object: internalFileDownload)
                    }
                    DDLogDebug(".failure: \(String(describing: error.errorDescription)))")
//                    self.stateSubject.onError(FileDownloadError.internalFailure(error))
                }
            }
        }
        return Single.just(())
    }
    
    public func deleteDownload() -> Single<Void> {
        return Single.create { [unowned self] single -> Disposable in
            if let internalFile: URL = self.internalFileDownload?.localUrl {
                do {
                    try FileManager.default.removeItem(atPath: internalFile.path)
                } catch {
                    single(.error(error))
                }
                single(.success(()))
            } else {
                single(.error(DeleteFileError.deleteFileFailed("file not found")))
            }
            return Disposables.create {}
        }
    }
}

public enum FileWebService {
    case download(url: String, filename: String?, fileExtension: String?)

    var localLocation: URL {
        switch self {
        case .download(let url, let filename, let fileExtension):

            var fileKey: String!

            if let filename = filename {
                fileKey = filename
                fileKey = fileKey.replacingOccurrences(of: " ", with: "_")
            } else {
                fileKey = url.MD5hex // use url's md5 as local file name
            }
            let directory: URL = FileSystem.savedDirectory
            var filePath: URL = directory.appendingPathComponent(fileKey)
            if let ext = fileExtension {
                // append path extension if exit
                let pathExtension: String = (ext as NSString).pathExtension.lowercased()
                filePath = filePath.appendingPathExtension(pathExtension)
            }
            DDLogDebug("filePath: \(filePath)")
            return filePath
        }
    }

    var downloadDestination: DownloadDestination {
        // `createIntermediateDirectories` will create directories in file path
        return { _, _ in return (self.localLocation, [.removePreviousFile, .createIntermediateDirectories]) }
    }
}

extension FileWebService: TargetType {

    public var baseURL: URL {
        switch self {
        case .download(let url, _, _):
            return URL(string: url)!
        }
    }

    public var path: String {
        switch self {
        case .download(_, _, _):
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .download(_, _, _):
            return .get
        }
    }

    public var parameters: [String: Any]? {
        switch self {
        case .download:
            return nil
        }
    }

    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    public var task: Task {
        switch self {
        case .download(_, _, _):
            return .downloadDestination(downloadDestination)
        }
    }

    public var downloadLocation: URL {
        return self.localLocation
    }

    public var sampleData: Data {
        return Data()
    }

    public var headers: [String: String]? {
        return nil
    }
}

/// FileProvider is a convenience struct on FileWebService
struct FileProvider {
    static let provider = MoyaProvider<FileWebService>(plugins: [NetworkLoggerPlugin(verbose: WebService.verbose)])

    static func request(target: FileWebService, progress: ProgressBlock?, completion: @escaping (WebService.Result) -> Void) -> Cancellable {
        return provider.request(target, progress: progress) { result in
            switch result {
            case let .success(response):
                let data = response.data
                //                let json = JSON(data: data)
                completion(.success(data))
            case .failure(_):
                completion(.failure("download fail"))
            }
        }
    }

}

class WebService {
    // set false when release
    static var verbose: Bool = true

    // response result type
    enum Result {
        case success(Data)
        case failure(String)
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

