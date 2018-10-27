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

public protocol FileDownloading {
    var url: URL { get }
    var localUrl: URL { get }
    var progress: Float { get }
    var totalCount: Int64 { get }
    var completedCount: Int64 { get }
}

public final class FileDownload {
    // MARK: Fields
    public let url: URL
    public let localUrl: URL
    public let progress: Float
    public let totalCount: Int64
    public let completedCount: Int64

    public init(url: URL,
                localUrl: URL,
                progress: Float,
                totalCount: Int64,
                completedCount: Int64) {
        self.url = url
        self.localUrl = localUrl
        self.progress = progress
        self.totalCount = totalCount
        self.completedCount = completedCount
    }

//    public var url: URL {
//        return url
//    }
//
//    public var progress: Float {
//        return progress
//    }
//
//    public var totalCount: UInt64 {
//        return totalCount
//    }
//
//    public var completedCount: UInt64 {
//        return completedCount
//    }
}

//extension FileDownload: FileDownloading {
//    public var url: URL {
//        return url
//    }
//
//    public var progress: Float {
//        return progress
//    }
//
//    public var totalCount: UInt64 {
//        return totalCount
//    }
//
//    public var completedCount: UInt64 {
//        return completedCount
//    }
//}

public enum FileDownloadState {
    case initial
    case initiating
    case inProgress
    case cancelling
    case complete
}

public enum FileDownloadError: Error {
    case internalFailure(Error?)
    case downloadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .internalFailure(let error):
            return "Internal file downloading error: \(String(describing: error))"
        case .downloadFailed(let reason):
            return "Download failed due to \(reason)"
        }
    }
}


//import SwiftyJSON

//protocol DownloadDataServicing {
//
//}

public protocol FileDownloadDataServicing {
    var state: Observable<FileDownloadState> { get }
//    var progress: Observable<Float> { get }
    var fileDownload: Observable<FileDownload> { get }
    func downloadFile(url: String, filename: String) -> Single<Void>
}

public final class DownloadDataService {

    // MARK: Fields
    private var stateSubject = BehaviorSubject<FileDownloadState>(value: .initial)
//    private var progressSubject: PublishSubject = PublishSubject<Float>()
    private var fileDownloadSubject: PublishSubject = PublishSubject<FileDownload>()
    private let fileWebService: MoyaProvider<FileWebService>!

    // the current download request
    private var internalRequest: Cancellable?

    public init(fileWebService: MoyaProvider<FileWebService>) {
        self.fileWebService = fileWebService
    }

    /*
     let provider = MoyaProvider<FileWebService>(plugins: [NetworkLoggerPlugin(verbose: WebService.verbose)])
     let urlString: String = "https://d2v5mbm9qwqitj.cloudfront.net/bible/en/0019-0001-Psalms-en.mp3"

     provider.request(FileWebService.download(url: urlString, fileName: nil), callbackQueue: nil, progress: { progressResponse in
     print("progressResponse: \(progressResponse)")
     }) { result in
     print("result: \(result)")
     switch result {
     case let .success(response):
     let statusCode = response.statusCode
     if let dataString: String = String(data: response.data, encoding: .utf8) {
     print(".success: \(dataString)")
     print(".success statusCode: \(statusCode)")
     }

     case .failure(_):
     if let error = result.error {
     print(".failure: \(String(describing: error.errorDescription)))")
     }
     }
     }

     //        FileProvider.request(target: FileWebService.download(url: urlString, fileName: nil), progress: { progressResult in
     //            print("progressResult: \(progressResult)")
     //        }) { webserviceResult in
     //            print("webserviceResult: \(webserviceResult)")
     //        }
     */

}


extension DownloadDataService: FileDownloadDataServicing {
    // MARK: Private Helpers

    private var currentState: FileDownloadState? {
        return try? stateSubject.value()
    }

    // MARK: Public API

    public var state: Observable<FileDownloadState> {
        return stateSubject.asObservable()
    }

//    public var progress: Observable<Float> {
//        return progressSubject.asObservable()
//    }

    public var fileDownload: Observable<FileDownload> {
        return fileDownloadSubject.asObservable()
    }


    public func cancel() {
        guard let currentState = currentState
            else { return }
        switch currentState {
        case .initial, .cancelling, .complete: return
        case .initiating, .inProgress:
            stateSubject.onNext(.cancelling)
//            internalWebsocket.close()
            if let internalRequest = internalRequest {
                internalRequest.cancel()
            }
        }
    }

    public func downloadFile(url: String, filename: String) -> Single<Void> {
        print("downloadFile url: \(url)")

        self.stateSubject.onNext(.initiating)

        let fileService: FileWebService = FileWebService.download(url: url, filename: filename, fileExtension: nil)
        let downloadLocation: URL = fileService.downloadLocation

//        target.localLocation
//        target.dow
        self.internalRequest = fileWebService.request(fileService, callbackQueue: nil, progress: { progressResponse in

//            self.progressSubject.onNext(Float(progressResponse.progress))

            if let totalUnitCount = progressResponse.progressObject?.totalUnitCount,
                let completedUnitCount = progressResponse.progressObject?.completedUnitCount,
                let remoteUrl = URL(string: url)
            {
                self.fileDownloadSubject.onNext(FileDownload(url: remoteUrl,
                                                             localUrl: downloadLocation,
                                                             progress: Float(progressResponse.progress),
                                                             totalCount: totalUnitCount,
                                                             completedCount: completedUnitCount))
            }
//            progressResponse.progressObject?.completedUnitCount
//            if progressObject = progressResponse.progressObject {
//            }
            // progressResponse.progressObject?.completedUnitCount
            // progressResponse.progressObject?.totalUnitCount
            if Float(progressResponse.progress) > 0.0 && Float(progressResponse.progress) < 1.0 {
                self.stateSubject.onNext(.inProgress)
            }
            print("progressResponse response statusCode: \(progressResponse.response?.statusCode)")
            print("progressResponse: \(progressResponse.progress)")
        }) { result in
            print("result: \(result)")
            switch result {
            case let .success(response):
                let statusCode = response.statusCode
                if let dataString: String = String(data: response.data, encoding: .utf8) {
                    print(".success: \(dataString)")
                    print(".success statusCode: \(statusCode)")

                    if statusCode == Int(200) {
                        self.stateSubject.onNext(.complete)
                    }
                }

            case .failure(_):
                if let error = result.error {
                    print(".failure: \(String(describing: error.errorDescription)))")
                    self.stateSubject.onError(FileDownloadError.internalFailure(error))
                }
            }
        }
        return Single.just(())
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
            print("filePath: \(filePath)")
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

