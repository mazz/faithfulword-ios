//
//  MainMenuTableViewCell.swift
//  RVG
//
//  Created by maz on 2017-05-11.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit

class MainMenuTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var iconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
