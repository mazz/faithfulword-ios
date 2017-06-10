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
    
    internal let bookApi :                                  String = "/v1/books"
    internal let gospelApi :                                String = "/v1/gospels"
    internal let supportedLanguageIdentifierApi :           String = "/v1/languages/supported"
    internal let allLanguageIdentifierApi :                 String = "/v1/languages"
    internal let mediaChapterApi :                          String = "/v1/books/{bid}/media"
    internal let mediaGospelApi :                           String = "/v1/gospels/{gid}/media"
    
    //internal let contactUsApi :     String = "/v1/contact-us"

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

    func getGospels(success: @escaping ([Gospel]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(gospelApi) {
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
                    var parsedObject: GospelResponse
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = GospelResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.gospels)
                        }
                    } catch {
                        print("error: \(error)")
                    }
                })
                
                task.resume()
            }
        }
        
    }

    func getMediaChapters(forBookId bookId: (String), success: @escaping ([MediaChapter]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(mediaChapterApi) {
                let finalUrlStr = urlStr.replacingOccurrences(of: "{bid}", with: bookId, options: .literal, range: nil)
                print("finalUrl: \(finalUrlStr)")
                
                let url = NSURL(string: finalUrlStr)
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                // request.setValue("es-US", forHTTPHeaderField:"Language-Id")
                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    var parsedObject: MediaChapterResponse
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = MediaChapterResponse(JSON: jsonObject)!
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
    
    func getMediaGospels(forGospelId gospelId: (String), success: @escaping ([MediaGospel]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(mediaChapterApi) {
                let finalUrlStr = urlStr.replacingOccurrences(of: "{gid}", with: gospelId, options: .literal, range: nil)
                print("finalUrl: \(finalUrlStr)")
                
                let url = NSURL(string: finalUrlStr)
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                // request.setValue("es-US", forHTTPHeaderField:"Language-Id")
                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    var parsedObject: MediaGospelResponse
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = MediaGospelResponse(JSON: jsonObject)!
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

    
    func getSupportedLanguageIdentifiers(success: @escaping ([LanguageIdentifier]?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(supportedLanguageIdentifierApi) {
                let finalUrlStr = urlStr
                print("finalUrl: \(finalUrlStr)")
                
                let url = NSURL(string: finalUrlStr)
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                // request.setValue("es-US", forHTTPHeaderField:"Language-Id")
                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    var parsedObject: LanguageIdentifierResponse
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = LanguageIdentifierResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.languageIdentifiers)
                        }
                    } catch {
                        print("error: \(error)")
                    }
                })
                
                task.resume()
            }
        }
        
    }

    /*
    func postContactUs(contactUsModel: (ContactUsModel), success: @escaping (Void) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
            if let urlStr = env.baseURL?.absoluteString?.appending(contactUsApi) {
//                let finalUrlStr = urlStr.replacingOccurrences(of: "{bid}", with: bookId, options: .literal, range: nil)
//                print("finalUrl: \(finalUrlStr)")
                
                let url = NSURL(string: urlStr)
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "POST"
                
                print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                print("userAgent: \(Device.userAgent())")
                print("platform: \(Device.platform())")
                request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                // request.setValue("es-US", forHTTPHeaderField:"Language-Id")
                request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
                
                do {
                    let json = try JSONSerialization.data(withJSONObject: ["name": contactUsModel.name, "email": contactUsModel.email, "message": contactUsModel.message, "signup": contactUsModel.signup], options: [.prettyPrinted])
                    request.httpBody = json

                } catch {
                    print("error: \(error)")
                }
                
                let session = URLSession.shared
                let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                    print("contact us response data: \(String(describing: data!))")
                    success()
                })
                
                task.resume()
            }
        }
    }
*/
}
