//
//  WebServiceSingleTon.swift
//  DemoWebservices
//
//  Created by Igniva-ios-12 on 11/4/16.
//  Copyright © 2016 Igniva-ios-12. All rights reserved.
//let dataExample: Data = NSKeyedArchiver.archivedData(withRootObject: dictionaryExample)

import Dispatch
import Foundation
import UIKit

class WebServiceSingleTon {
    var loading : LoadingIndicator?
    static var object :  WebServiceSingleTon?
    
    class func sharedInstance() -> WebServiceSingleTon {
        DispatchQueue.once(token: dispatchWebservice) {
            object = WebServiceSingleTon()
        }
        return object!;
    }
    
    func showIndicator() {
        loading = LoadingIndicator(frames:UIScreen.main.bounds)
        UIApplication.shared.keyWindow?.addSubview(loading!)
    }
    
    func HideIndicator() {
        loading?.removeFromSuperview()
        loading = nil
    }
    
    //    func convertDictionaryToString (dic : NSDictionary) -> String
    //    {
    //        var str = ""
    //        let keys = dic.allKeys;
    //        for index in 0..<dic.allKeys.count {
    //            str = str.appending(keys[index] as! String)
    //            str = str.appending("=")
    //            str = str.appending(dic.object(forKey: keys[index] as! String) as! String)
    //            if index < dic.allKeys.count-1
    //            {
    //                str = str.appending("&")
    //            }
    //        }
    //        return str
    //    }
    
    func convertDictionaryToString (dic : NSDictionary) -> String
    {
        let data: NSData? = try! JSONSerialization.data(withJSONObject: dic, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData?
        
        var jsonStr: String?
        if data != nil {
            
            jsonStr = String(data: data! as Data, encoding: String.Encoding.utf8)
            return jsonStr!
        }
        return ""
    }
    
    //Post Web Service
    func PostRequest (params:NSDictionary,linkUrl:String,indicator:Bool,success:@escaping (NSDictionary) -> (), errors:@escaping (String) -> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus == .notReachable){
            errors("Internet not available")
        }
        else{
            if indicator == true
            {
                showIndicator()
            }
            let urlStr = BASE_URL.appending(linkUrl)
            let url = NSURL(string: urlStr)
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")
       //     request.timeoutInterval = 10.0
            
            let bodyStr = convertDictionaryToString(dic: params)
            let bodyData = bodyStr.data(using: String.Encoding.utf8, allowLossyConversion: true)
            request.httpBody = bodyData
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                
                            if indicator == true
                            {
                                DispatchQueue.main.async {
                                    self.HideIndicator()
                                }
                            }
                
                if(error==nil)
                {
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                            //DDLogDebug(jsonResult)
                            DispatchQueue.main.async {
                                success(jsonResult)}
                        }
                    } catch let error1 as NSError {
                        DispatchQueue.main.async {
                            //DDLogDebug(error1.localizedDescription)
                            errors(error1.localizedDescription)
                            self.HideIndicator()
                        }
                    }
                }
                else
                {
                    //DDLogDebug(error)
                    DispatchQueue.main.async {
                        self.HideIndicator()
                        errors((error?.localizedDescription)!)
                    }
                }
                
            });
            
            task.resume()
        }
    }
    
    //Delete Web Service
    func deleteRequest (params:NSDictionary,linkUrl:String,indicator:Bool,success:@escaping (NSDictionary) -> (), errors:@escaping (String) -> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus == .notReachable){
            errors("Internet not available")
        }
        else{
            if indicator == true
            {
                showIndicator()
            }
            let urlStr = BASE_URL.appending(linkUrl)
            let url = NSURL(string: urlStr)
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")
            //     request.timeoutInterval = 10.0
            
            let bodyStr = convertDictionaryToString(dic: params)
            let bodyData = bodyStr.data(using: String.Encoding.utf8, allowLossyConversion: true)
            request.httpBody = bodyData
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                
                if indicator == true
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                    }
                }
                
                if(error==nil)
                {
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                            //DDLogDebug(jsonResult)
                            DispatchQueue.main.async {
                                success(jsonResult)}
                        }
                    } catch let error1 as NSError {
                        DispatchQueue.main.async {
                            //DDLogDebug(error1.localizedDescription)
                            errors(error1.localizedDescription)
                            self.HideIndicator()
                        }
                    }
                }
                else
                {
                    //DDLogDebug(error)
                    DispatchQueue.main.async {
                        self.HideIndicator()
                        errors((error?.localizedDescription)!)
                    }
                }
                
            });
            
            task.resume()
        }
    }

    
    //Put Web Service
    func PutRequest (params:NSDictionary,linkUrl:String,indicator:Bool,success:@escaping (NSDictionary) -> (), errors:@escaping (String) -> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus == .notReachable){
            errors("Internet not available")
        }
        else{
            if indicator == true
            {
                showIndicator()
            }
            let urlStr = BASE_URL.appending(linkUrl)
            let url = NSURL(string: urlStr)
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")
    //        request.timeoutInterval = 10.0
            
            let bodyStr = convertDictionaryToString(dic: params)
            let bodyData = bodyStr.data(using: String.Encoding.utf8, allowLossyConversion: true)
            request.httpBody = bodyData
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                
                if indicator == true
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                    }
                }
                
                if(error==nil)
                {
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                            //DDLogDebug(jsonResult)
                            DispatchQueue.main.async {
                                success(jsonResult)}
                        }
                    } catch let error1 as NSError {
                        DispatchQueue.main.async {
                            //DDLogDebug(error1.localizedDescription)
                            errors(error1.localizedDescription)
                            self.HideIndicator()
                        }
                    }
                }
                else
                {
                    //DDLogDebug(error)
                    DispatchQueue.main.async {
                        self.HideIndicator()
                        errors((error?.localizedDescription)!)
                    }
                }
                
            });
            
            task.resume()
        }
    }
    
    //GET web service
    func getRequest (linkUrl:String,indicator:Bool,success:@escaping ([AnyObject]) -> (), errors:@escaping (String) -> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus == .notReachable){
            errors("Internet not available")
        }
        else{
            if indicator == true
            {
                showIndicator()
            }
            var urlStr = BASE_URL.appending(linkUrl)
            urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
            let url = NSURL(string: urlStr)
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")
     //       request.timeoutInterval = 10.0
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                
                            if indicator == true
                            {
                                DispatchQueue.main.async {
                                    self.HideIndicator()
                                }
                            }
                
                
                
//                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//                DDLogDebug(responseString)
                
                if(error==nil)
                {
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? [AnyObject] {
                        //    DDLogDebug(jsonResult)
                            DispatchQueue.main.async {
                            success(jsonResult)
                            }
                        }else{
                            
                        }
                    } catch let error1 as NSError {
                        DDLogDebug(error1.localizedDescription)
                        DispatchQueue.main.async {
                            errors(error1.localizedDescription)
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                        errors((error?.localizedDescription)!)
                    }
                    //DDLogDebug(error)
                }
                
            });
            
            task.resume()
        }
    }
    
    //MARK: method for Upload Image...
    func putWebservicesWithMultipartImage(input: NSDictionary , indicator : Bool , url:String, picData:[Data],completion: @escaping (_ result:NSDictionary?) -> Void, Err: @escaping (_ error: NSError)-> (), Unreachable: (_ noNet: String)-> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus != .notReachable){
            //DDLogDebug("Internet connection OK")
            if(indicator == true)
            {
                showIndicator()
            }
            let request = NSMutableURLRequest(url: NSURL(string: BASE_URL.appending(url) ) as! URL);
            request.httpMethod = "PUT";
            let boundary = NSString(format: "---------------------------14737809831466499882746641449") as String
            
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("multipart/form-data; boundary="+boundary, forHTTPHeaderField: "Content-Type")
            let data = createBodyWithParameters(parameters: input, filePathKey:nil, imageDataKey: picData, boundary: boundary)
            //DDLogDebug(data)
            request.httpBody = data
            let task = URLSession.shared.dataTask(with: request as URLRequest)
            {
                data, response, error in
                if(indicator == true)
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                    }
                }
                if error != nil
                {
                    DispatchQueue.main.async {
                        Err(error! as NSError)
                    }
                    return
                }
                // Print out reponse body
        //        let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                //DDLogDebug("****** response data = \(responseString!)")
                do
                {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    //DDLogDebug(json)
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        
                        DispatchQueue.main.async {
                            if(json != nil)
                            {
                                completion(json)
                            }
                        }
                    }
                }
                catch
                {
                    DispatchQueue.main.async {
                        Err(error as NSError)
                    }
                }
            }
            task.resume()
        }
        else {
            //DDLogDebug("Internet connection FAILED")
            Unreachable("Internet not available")
        }
    }

    
    
    //MARK: method for Upload Image...
    func getWebservicesWithMultipartImage(input: NSDictionary , indicator : Bool , url:String, picData:[Data],completion: @escaping (_ result:NSDictionary?) -> Void, Err: @escaping (_ error: NSError)-> (), Unreachable: (_ noNet: String)-> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus != .notReachable){
            //DDLogDebug("Internet connection OK")
            if(indicator == true)
            {
                showIndicator()
            }
            let request = NSMutableURLRequest(url: NSURL(string: BASE_URL.appending(url) ) as! URL);
            request.httpMethod = "POST";
            let boundary = NSString(format: "---------------------------14737809831466499882746641449") as String
            
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("multipart/form-data; boundary="+boundary, forHTTPHeaderField: "Content-Type")
            let data = createBodyWithParameters(parameters: input, filePathKey:nil, imageDataKey: picData, boundary: boundary)
            //DDLogDebug(data)
            request.httpBody = data
            let task = URLSession.shared.dataTask(with: request as URLRequest)
            {
                data, response, error in
                if(indicator == true)
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                    }
                }
                if error != nil
                {
                    DispatchQueue.main.async {
                        Err(error! as NSError)
                    }
                    return
                }
                // Print out reponse body
 //               let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                //DDLogDebug("****** response data = \(responseString!)")
                do
                {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    //DDLogDebug(json)
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        
                        DispatchQueue.main.async {
                            if(json != nil)
                            {
                                completion(json)
                            }
                        }
                    }
                }
                catch
                {
                    DispatchQueue.main.async {
                        Err(error as NSError)
                    }
                }
            }
            task.resume()
        }
        else {
            //DDLogDebug("Internet connection FAILED")
            Unreachable("Internet not available")
        }
    }
    
    //******* Method for sending an Image in an Multipart Form *******//
    
    
    func createBodyWithParameters(parameters:NSDictionary, filePathKey: String?, imageDataKey: [Data], boundary: String) -> Data {
        
        var body = Data();
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        for index in 0..<imageDataKey.count{
            let mimetype = "image.jpeg"
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            let str = "file".appendingFormat("%i", index+1)
            body.append("Content-Disposition: form-data; name=\"\(str)\"; filename=\"\(mimetype)\"\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append(imageDataKey[index])
            body.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        }
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        return body
    }
    
    //MARK: method for Upload Image...
    func uploadSingleImage(input: NSDictionary , indicator : Bool , url:String, picData:Data,completion: @escaping (_ result:NSDictionary?) -> Void, Err: @escaping (_ error: NSError)-> (), Unreachable: (_ noNet: String)-> ())
    {
        let reachability = Reachability()!
        if(reachability.currentReachabilityStatus != .notReachable){
            //DDLogDebug("Internet connection OK")
            if(indicator == true)
            {
                showIndicator()
            }
            let request = NSMutableURLRequest(url: NSURL(string: BASE_URL.appending(url) ) as! URL);
            request.httpMethod = "POST";
            let boundary = NSString(format: "---------------------------14737809831466499882746641449") as String
            
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("multipart/form-data; boundary="+boundary, forHTTPHeaderField: "Content-Type")
            let data = createBodyWithParametersForSingleImage(parameters: input, filePathKey:nil, imageDataKey: picData, boundary: boundary)
            //DDLogDebug(data)
            request.httpBody = data
            let task = URLSession.shared.dataTask(with: request as URLRequest)
            {
                data, response, error in
                if(indicator == true)
                {
                    DispatchQueue.main.async {
                        self.HideIndicator()
                    }
                }
                if error != nil
                {
                    DispatchQueue.main.async {
                        Err(error! as NSError)
                    }
                    return
                }
                // Print out reponse body
 //               let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                //DDLogDebug("****** response data = \(responseString!)")
                do
                {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    //DDLogDebug(json)
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        
                        DispatchQueue.main.async {
                            if(json != nil)
                            {
                                completion(json)
                            }
                        }
                    }
                }
                catch
                {
                    DispatchQueue.main.async {
                        Err(error as NSError)
                    }
                }
            }
            task.resume()
        }
        else {
            //DDLogDebug("Internet connection FAILED")
            Unreachable("Internet not available")
        }
    }
    
    //******* Method for sending an Image in an Multipart Form *******//
    
    
    func createBodyWithParametersForSingleImage(parameters:NSDictionary, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
        
        var body = Data();
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        let mimetype = "image.jpeg"
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        let str = "file"
        body.append("Content-Disposition: form-data; name=\"\(str)\"; filename=\"\(mimetype)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(imageDataKey)
        body.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        return body
    }
}





/*
 func getRequest ()
 {
 let request:  NSURLRequest = NSURLRequest(url:NSURL(string:"url")! as URL)
 let config  = URLSessionConfiguration.default
 let session = URLSession(configuration: config)
 
 let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
 
 if(error==nil)
 {
 do {
 if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
 //DDLogDebug(jsonResult)
 }
 } catch let error as NSError {
 //DDLogDebug(error.localizedDescription)
 }
 }
 else
 {
 //DDLogDebug(error)
 }
 
 });
 
 task.resume()
 }

 */




