//
//  ModelOfViewControllerFolders.swift
//  RVG
//

import UIKit

class ModelOfViewControllerFolders {

    var id : String?
    var nameInSpanish : String?
    var nameInEnglish : String?
    
    func setModelValues (dictionary:[String:AnyObject]){
        if let id = dictionary["id"] as? String{
          self.id=id
        }
        if let nameInSpanish = dictionary["NameInSpanish"] as? String{
            self.nameInSpanish=nameInSpanish
        }
        if let nameInEnglish = dictionary["NameInEnglish"] as? String{
            self.nameInEnglish=nameInEnglish
        }
    }

}
