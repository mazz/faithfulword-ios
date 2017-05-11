//
//  CollectionViewCellVc.swift
//  RVG
//
//  Created by Charanbir Sandhu on 28/02/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
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
