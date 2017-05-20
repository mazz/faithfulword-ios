//
//  ModelSongClass.swift
//  RVG
//

import UIKit

class ModelSongClass {

    var id : String?
    var trackNameInSpanish : String?
    var trackNameInEnglish : String?
    var trackPath : String?
    
    func setModelValues (dictionary:[String:AnyObject]){
        if let id = dictionary["id"] as? String{
            self.id=id
        }
        if let trackNameInSpanish = dictionary["TrackNameInSpanish"] as? String{
            self.trackNameInSpanish=trackNameInSpanish
        }
        if let trackNameInEnglish = dictionary["TrackNameInEnglish"] as? String{
            self.trackNameInEnglish=trackNameInEnglish
        }
        if let trackPath = dictionary["trackFrombucket"] as? String{
            self.trackPath=trackPath
        }
    }
    
}
