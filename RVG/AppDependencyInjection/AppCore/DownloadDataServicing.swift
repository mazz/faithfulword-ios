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

//import SwiftyJSON

//protocol DownloadDataServicing {
//
//}

protocol FileDownloadDataServicing {
    func downloadFile(url: String) -> Single<Void>
}

public final class DownloadDataService {
    private let fileWebService: MoyaProvider<FileWebService>!

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
    func downloadFile(url: String) -> Single<Void> {
        print("downloadFile url: \(url)")
        return Single.just(())
    }

}

public enum FileWebService {
    case download(url: String, fileName: String?)

    var localLocation: URL {
        switch self {
        case .download(let url, let fileName):
            let fileKey: String = url.MD5hex // use url's md5 as local file name
            let directory: URL = FileSystem.savedDirectory
            var filePath: URL = directory.appendingPathComponent(fileKey)
            if let name = fileName {
                // append path extension if exit
                let pathExtension: String = (name as NSString).pathExtension.lowercased()
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
        case .download(let url, _):
            return URL(string: url)!
        }
    }

    public var path: String {
        switch self {
        case .download(_, _):
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .download(_, _):
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
        case .download(_, _):
            return .downloadDestination(downloadDestination)
        }
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

