//
//  CommonMethodsClass.swift
//  SpiceMint_Merchant
//
//  Created by Igniva-ios-12 on 11/15/16.
//  Copyright © 2016 Igniva-ios-12. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CommonMethodsClass {
    
    class func zipCodeToAddress (zipCode:String,success:@escaping (CLPlacemark) -> ())
    {
        let geoCoder = CLGeocoder();
        geoCoder.geocodeAddressString(zipCode) { (placemarks, error) in
            let placemark = placemarks?[0]
            success(placemark!)
        }
    }
    
//    class func isSessionExpire(data:NSDictionary){
//        if(data.isKeyAvailable(key: "statusCode")){
//            if  let statusCode = data.value(forKey: "statusCode") as? NSNumber{
//                //print(statusCode)
//                if("\(statusCode)" == "1000"){
//                    DispatchQueue.main.async {
//                        AppDelegate.shareInstance().makeLoginToRootVc()
//                        Login.deleteData()
//                        Category.deleteData()
//                        if let msg = data.value(forKey: "message") as? String{
//                            CommonMethodsClass.showSingleButtonAlertWithoutActionOnAppDelegate(title: msg)
//                        }
//                    }
//                }
//            }
//        }
//        
//    }
    
    //show alert for only display information
    class func showSingleButtonAlertWithoutActionOnAppDelegate (title:String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    class func ConvertorStringFromDate(dateStr: Date) -> String
    {
        
        let df = DateFormatter()
        
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        let string = df.string(from: dateStr)
        
        return string
    }
    
    class func dateFormatConvertorFromstyring(dateString: String) -> String
    {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        let dateObj = dateFormatter.date(from: dateString)
        
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm a"
        
        return dateFormatter.string(from: dateObj!)
    }
    
    class func dateFormatGetOnlyDayMonth(dateS: String) -> String
    {
     //   let dateString = dateS.replacingOccurrences(of: "Z", with: "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
        let date = dateFormatter.date(from: dateS)// create   date from string
        
        // change to a readable time format and change to local time zone
    //    dateFormatter.dateFormat = "EEE, MMM d, yyyy - h:mm a"
        dateFormatter.dateFormat = "MMM d"
        dateFormatter.timeZone = NSTimeZone.local
        let timeStamp = dateFormatter.string(from: date!)
        
        return timeStamp
    }
    
    class func openWhatsapp(){
        let urlWhats = "whatsapp://?"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                    UIApplication.shared.open(whatsappURL as URL, options: [:], completionHandler: { (Bool) in
                        
                    })
                } else {

//                obj.showSingleButtonAlertWithoutAction(title: "Whats app is not installed in your device.")
                }
            }else{
                
            }
        } else{
            
        }
    }
    
    class func createCall(busPhone:String){
        if let url = URL(string: "tel://\(busPhone)") , UIApplication.shared.canOpenURL(url) {
       //     UIApplication.shared.openURL(url)
            UIApplication.shared.open(url, options: [:], completionHandler: { (tru) in
                
            })
        }
    }
    
    func findLargestNumberInIntArray(array:[Int])->Int{
        var number : Int? = 0;
        if(array.count>0){
            number = array[0]
        }
        for i in 0..<array.count{
            if (number!<array[i]){
                number = array[i]
            }
        }
        return number!
    }
    
}
