//
//  CollectionViewCellVc.swift
//  RVG
//

import UIKit

class CollectionViewCellVc: UICollectionViewCell {
    @IBOutlet weak var lbl: UILabel!
    
    func setData(obj:ModelOfViewControllerFolders){
        if language == "english" {
            lbl.text = obj.nameInEnglish
        }
        else {
            lbl.text = obj.nameInSpanish
        }
    }
    
}
