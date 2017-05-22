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
    
    internal let folderApi :        String = "/v1/book"
    internal let contactUsApi :     String = "/v1/contact-us"

    class func sharedInstance() -> BibleService {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.bibleservice") {
            bibleService = BibleService()
        }
        return bibleService!
    }
    
    func getBooks(success: @escaping ([Book]?) -> (), errors: @escaping (String) -> ()) -> () {
        
        let reachability = Reachability()!

        if (reachability.currentReachabilityStatus == .notReachable) {
            errors("Internet not available")
        }
        else {
            
            let env: Environment = EnvironmentService.sharedInstance().connectedEnvironment()
            print("env: \(env)")
            
            if let urlStr = env.baseURL?.absoluteString?.appending(folderApi) {
                //.appending(linkUrl)
                print("urlStr: \(urlStr)")
                let url = NSURL(string: urlStr)
                
                let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
                request.httpMethod = "GET"
                request.setValue("es", forHTTPHeaderField:"Language-Id")
                
                let session = URLSession.shared
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                    
                    if (error == nil) {
                        do {
                            let jsonString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                            
                            
//                            guard let jsonObject = json as? [String:Any] else {
////                                throw Error.jsonError("JSON is not an object: \(json)")
//                                print("json error")
//                                return
//                            }

//                            guard let parsedObject = T(JSON: jsonObject) else {
////                                throw ASError.jsonError(“Could not decode json object: \(jsonObject)“)
//                                print("parse error")
//                            }
//                            let book = BookResponse(map: json as! Map)
                            var parsedObject: BookResponse
                            // doesn't work, but should
                            let json = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
                            if let jsonObject = json as? [String:Any] {
                                parsedObject = BookResponse(JSON: jsonObject)!
                                print(parsedObject)
                                success(parsedObject.books)
                            }
                            

//                            let bookResponse = Mapper<BookResponse>().map(JSONString: jsonString as! String)
//
//                            if parsedObject != nil {
//                                DispatchQueue.main.async {
//                                    success(parsedObject.books)
//                            }
                        }
                        catch let error1 as NSError {
                            DispatchQueue.main.async {
                                //print(error1.localizedDescription)
                                errors(error1.localizedDescription)
//                                self.HideIndicator()
                            }
                        }
                    }
                    else {
                        print(error)
                        DispatchQueue.main.async {
//                            self.HideIndicator()
                            errors((error?.localizedDescription)!)
                        }
                    }
                    
                });
                
                task.resume()
                
            }
            
        }
    }
}
