//
//  BaseClass.swift
//  DemoWebservices
//
//  Created by Igniva-ios-12 on 11/4/16.
//  Copyright © 2016 Igniva-ios-12. All rights reserved.
// let accessoryImage = UIImage(named:"alert")
//ok.setValue(accessoryImage, forKey: "image")
//
import UIKit
import CoreLocation



class BaseClass: UIViewController, UINavigationControllerDelegate {
    var isSentLoc = false
    var loading : LoadingIndicator?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    //show alert for only display information
    func showSingleButtonAlertWithoutAction (title:String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
        //alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //show alert with Single Button action
    func showSingleButtonAlertWithAction (title:String,buttonTitle:String,completionHandler:@escaping (Void) -> ()) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.default, handler: { action in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //show alert with right action button
    func showTwoButtonAlertWithRightAction (title:String,buttonTitleLeft:String,buttonTitleRight:String,completionHandler:@escaping (Void) -> ()) {
        let alert = UIAlertController(title: "", message: title, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: buttonTitleLeft, style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: buttonTitleRight, style: UIAlertActionStyle.default, handler: { action in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //show alert with left action button
    func showTwoButtonAlertWithLeftAction (title:String,buttonTitleLeft:String,buttonTitleRight:String,completionHandler:@escaping (Void) -> ()) {
        let alert = UIAlertController(title: "KJV RVG", message: title, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: buttonTitleLeft, style: UIAlertActionStyle.default, handler: { action in
            completionHandler()
        }))
        alert.addAction(UIAlertAction(title: buttonTitleRight, style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //show alert with two action button
    func showTwoButtonAlertWithTwoAction (title:String,buttonTitleLeft:String,buttonTitleRight:String,completionHandlerLeft:@escaping (Void) -> (),completionHandlerRight:@escaping (Void) -> ()) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: buttonTitleLeft, style: UIAlertActionStyle.default, handler: { action in
            completionHandlerLeft()
        }))
        alert.addAction(UIAlertAction(title: buttonTitleRight, style: UIAlertActionStyle.default, handler: { action in
            completionHandlerRight()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //show full screen indicator
    func showIndicator() {
        HideIndicator()
        loading = LoadingIndicator(frames:UIScreen.main.bounds)
        view.addSubview(loading!)
    }
    
    //hide full screen indicator
    func HideIndicator() {
        loading?.removeFromSuperview()
        loading = nil
    }
    
    //storyboard instance
    func storyBoadName(name:String) ->UIStoryboard {
        return UIStoryboard(name:name,bundle:nil)
    }
    
    //return vc by name
    func pushVc (strBdName: String,vcName:String) ->UIViewController {
        return UIStoryboard(name:strBdName,bundle:nil).instantiateViewController(withIdentifier: vcName)
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func passwordValidationAlphaNumeric(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
//        let emailRegEx = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[$@$!%*#?&])[A-Za-z\\d$@$!%*#?&]{6,15}$"
        let emailRegEx = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!#$%&'()*+,-./:;<=>?@^_`{|}~\"])[A-Za-z\\d!#$%&'()*+,-./:;<=>?@^_`{|}~\"]{6,15}$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func UK_postalCodeValidation(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "(GIR 0AA)|((([A-Z-[QVX]][0-9][0-9]?)|(([A-Z-[QVX]][A-Z-[IJZ]][0-9][0-9]?)|(([A-Z-[QVX]][0-9][A-HJKPSTUW])|([A-Z-[QVX]][A-Z-[IJZ]][0-9][ABEHMNPRVWXY])))) [0-9][A-Z-[CIKMOV]]{2})"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func phoneNumberOfUK(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "^(?=.*[0-9])[0-9- ]{10,14}$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func sortceCodeValidation(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "^(\\d){2}-(\\d){2}-(\\d){2}$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func accountNumberValidation(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "^[0-9]+$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func onlyDecimal(testStr:String) -> Bool {
        // //print("validate calendar: \(testStr)")
        let emailRegEx = "^[0-9.]+$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    /*
 Minimum 8 characters at least 1 Alphabet and 1 Number:
 
 "^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$"
 Minimum 8 characters at least 1 Alphabet, 1 Number and 1 Special Character:
 
 "^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?&])[A-Za-z\d$@$!%*#?&]{8,}$"
 Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet and 1 Number:
 
 "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$"
 Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character:
 
 "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}"
 Minimum 8 and Maximum 10 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character:
 
 "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,10}"
     */
    
}
