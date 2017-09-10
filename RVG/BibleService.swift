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
    
    internal let supportedLanguageIdentifierApi :           String = "/v1.1/languages/supported"
    internal let musicApi :                                 String = "/v1.1/music"
    internal let mediaMusicApi :                            String = "/v1.1/music/{mid}/media"
    
    let timeoutInterval : TimeInterval = 30
    
    //internal let contactUsApi :     String = "/v1/contact-us"

    class func sharedInstance() -> BibleService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.bibleservice") {
            bibleService = BibleService()
        }
        return bibleService!
    }
    
    func getSupportedLanguageIdentifiers(success: @escaping ([LanguageIdentifier]?) -> ()) throws -> () {
        
        do {
            try BibleService.sharedInstance().makeRequest(method: "GET", endpointPath: supportedLanguageIdentifierApi, languageIdentifier: Device.preferredLanguageIdentifier()) { (data, urlResponse, error) in
                
                var parsedObject: LanguageIdentifierResponse
                do {
                    if let _ = data {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = LanguageIdentifierResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.languageIdentifiers)
                        }
                    } else {
                        throw SessionError.jsonParseFailed
                    }
                } catch {
                    print("error: \(error)")
                }
            }
        } catch let error {
            print("BibleService getMediaGospels error: \(error)")
            throw error
        }
    }
    
    func getMusic(success: @escaping ([Music]?) -> ()) throws -> () {
        
        do {
            try BibleService.sharedInstance().makeRequest(method: "GET", endpointPath: musicApi, languageIdentifier: Device.preferredLanguageIdentifier()) { (data, urlResponse, error) in
                
                var parsedObject: MusicResponse
                do {
                    if let _ = data {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = MusicResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.music)
                        }
                    } else {
                        throw SessionError.jsonParseFailed
                    }
                } catch {
                    print("error: \(error)")
                }
            }
        } catch let error {
            print("BibleService getMusic error: \(error)")
            throw error
        }
    }
    
    func getMediaMusic(forMusicId musicId: (String), success: @escaping ([MediaMusic]?) -> ()) throws -> () {
        do {
            let finalPathString = mediaMusicApi.replacingOccurrences(of: "{mid}", with: musicId, options: .literal, range: nil)
            
            try BibleService.sharedInstance().makeRequest(method: "GET", endpointPath: finalPathString, languageIdentifier: Device.preferredLanguageIdentifier()) { (data, urlResponse, error) in
                
                var parsedObject: MediaMusicResponse
                do {
                    if let _ = data {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                        if let jsonObject = json as? [String:Any] {
                            parsedObject = MediaMusicResponse(JSON: jsonObject)!
                            print(parsedObject)
                            success(parsedObject.media)
                        }
                    } else {
                        throw SessionError.jsonParseFailed
                    }
                } catch {
                    print("error: \(error)")
                }
            }
        } catch let error {
            print("BibleService getMediaMusic error: \(error)")
            throw error
        }
    }

    
    private func makeRequest(method : String, endpointPath : String, languageIdentifier : String?, success: @escaping (Data?, URLResponse?, Error?) -> ()) throws -> () {
        let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
        
        let reachability = Reachability()!
        
        if (reachability.currentReachabilityStatus == .notReachable) {
            throw SessionError.urlNotReachable
        }
        else {
                        if let urlStr = env.baseURL?.absoluteString?.appending(endpointPath) {
                            let url = NSURL(string: urlStr)
                            let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                            request.httpMethod = method
                            request.timeoutInterval = timeoutInterval
                            
                            print("preferredLanguageIdentifier: \(Device.preferredLanguageIdentifier())")
                            print("userAgent: \(Device.userAgent())")
                            print("platform: \(Device.platform())")
            
                            request.setValue(Device.preferredLanguageIdentifier(), forHTTPHeaderField:"Language-Id")
                            request.setValue(Device.userAgent(), forHTTPHeaderField:"User-Agent")
            
                            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, urlResponse, error) in
                                success(data, urlResponse, error)
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
