//
//  SongCellTableViewCell.swift
//  RVG
//
//  Created by Charanbir Sandhu on 01/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class SongCellTableViewCell: UITableViewCell {

    @IBOutlet weak var lbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setValues(_ obj:ModelSongClass){
        if language == "english" {
            lbl.text=obj.trackNameInEnglish
        }
        else {
            lbl.text=obj.trackNameInSpanish
        }
    }
}
