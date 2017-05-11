//
//  ContactUsBusinessLogicClass.swift
//  RVG
//
//  Created by Charanbir Sandhu on 05/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class ContactUsBusinessLogicClass {

    func checkValidations(obj:ContactUsViewController){
        obj.objModel.name=obj.txtName.text
        obj.objModel.email=obj.txtEmail.text
        obj.objModel.message=obj.txtMessage.text
        if !((obj.txtName.text?.characters.count)!>0){
            if language == "english" {
                obj.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Please fill out your name", comment: ""))
            }
//            else {
//                obj.showSingleButtonAlertWithoutAction(title: "Por favor escribe tu nombre")
//            }
        }
        else if !((obj.txtEmail.text?.characters.count)!>0) {
            if language == "english" {
                obj.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Please fill out your email address", comment: ""))
            }
//            else {
//                obj.showSingleButtonAlertWithoutAction(title: "Por favor, complete su dirección de correo electrónico")
//            }
        }
        else if obj.isValidEmail(testStr: obj.txtEmail.text!) == false {
            if language == "english" {
                obj.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Please fill out your email address", comment: ""))
            }
//            else {
//                obj.showSingleButtonAlertWithoutAction(title: "Por favor, complete su dirección de correo electrónico")
//            }
        }
        else if !(obj.txtMessage.text.characters.count>0) {
            if language == "english" {
                obj.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Please fill out your message", comment: ""))
            }
//            else {
//                obj.showSingleButtonAlertWithoutAction(title: "Por favor, complete su mensaje")
//            }
        }
        else {
            hitService(obj: obj)
        }
    }
    
    func hitService(obj:ContactUsViewController) {
        let params = ["name":obj.objModel.name!,"email":obj.objModel.email!,"message":obj.objModel.message!]
        WebServiceSingleTon().PostRequest(params: params as NSDictionary, linkUrl: contactUs, indicator: true, success: { (data) in
            
            print(data)
            obj.lblEmail.text = ""
            obj.lblMessage.text = ""
            obj.lblName.text = ""
            
            if language == "english" {
                obj.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Thank you, we will contact you soon", comment: ""))
            }
//            else {
//                obj.showSingleButtonAlertWithoutAction(title: "Gracias, nos pondremos en contacto contigo pronto")
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                _ = obj.navigationController?.popViewController(animated: true)
            }
            }) { (err) in
                obj.showSingleButtonAlertWithoutAction(title: err)
        }
    }
    
}
