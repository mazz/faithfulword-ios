//
//  NetworkService.swift
//  RVG
//
//  Created by michael on 2017-07-06.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class NetworkService {
    static var networkService :  NetworkService?

    internal let bookApi :                                  String = "/v1/books"
    internal let gospelApi :                                String = "/v1/gospels"
    internal let supportedLanguageIdentifierApi :           String = "/v1/languages/supported"
    internal let allLanguageIdentifierApi :                 String = "/v1/languages"
    internal let mediaChapterApi :                          String = "/v1/books/{bid}/media"
    internal let mediaGospelApi :                           String = "/v1/gospels/{gid}/media"

    //internal let contactUsApi :     String = "/v1/contact-us"

    class func sharedInstance() -> NetworkService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.networkservice") {
            networkService = NetworkService()
        }
        return networkService!
    }

    func makeRequest(request: NSURLRequest, success: @escaping (Data?) -> ()) throws -> () {
//        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
//
//        let reachability = Reachability()!
//
//        if (reachability.currentReachabilityStatus == .notReachable) {
//            throw SessionError.urlNotReachable
//        }
//        else {
//            if let urlStr = env.baseURL?.absoluteString?.appending(bookApi) {
//                let url = NSURL(string: urlStr)
//                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
//                request.httpMethod = "GET"
//
//                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
//                print("userAgent: \(Device.userAgent())")
//                print("platform: \(Device.platform())")
//
//                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
//                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
//
//                let session = URLSession.shared
//
//                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
//                    var parsedObject: BookResponse
//
//                    do {
//                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
//                        if let jsonObject = json as? [String:Any] {
//                            parsedObject = BookResponse(JSON: jsonObject)!
//                            print(parsedObject)
//                            success(parsedObject.books)
//                        }
//                    } catch {
//                        print("error: \(error)")
//                    }
//                })
//
//                task.resume()
//            }
//        }

    }
}
