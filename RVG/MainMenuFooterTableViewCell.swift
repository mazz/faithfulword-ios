//
//  MainMenuFooterTableViewCell.swift
//  RVG
//
//  Created by maz on 2017-05-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit

class MainMenuFooterTableViewCell: UITableViewCell {

    @IBOutlet weak var verseBodyLabel: UILabel!
    @IBOutlet weak var chapterAndVerseLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
