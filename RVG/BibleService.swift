//
//  BibleService.swift
//  RVG
//
//  Created by maz on 2017-05-20.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import ObjectMapper

class BibleService {
    static var bibleService :  BibleService?
    
    internal let bookApi :        String = "/v1/book"
    internal let contactUsApi :     String = "/v1/contact-us"

    class func sharedInstance() -> BibleService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.bibleservice") {
            bibleService = BibleService()
        }
        return bibleService!
    }
    
    func getBooks(success: @escaping ([Book]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()

        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(bookApi) {
                let url = NSURL(string: urlStr)
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    var parsedObject: BookResponse
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = BookResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.books)
                        }
                    } catch {
                        print("error: \(error)")
                    }
                })
                
                task.resume()
            }
        }
        
    }
    
    func getMedia(forBookId bookId: (String), success: @escaping ([Media]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(bookApi) {
                let url = NSURL(string: urlStr.appending("/\(bookId)"))
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                request.setValue("es-US", forHTTPHeaderField:"Language-Id")
//                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    var parsedObject: MediaResponse
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = MediaResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.media)
                        }
                    } catch {
                        print("error: \(error)")
                    }
                })
                
                task.resume()
            }
        }
        
    }
}
