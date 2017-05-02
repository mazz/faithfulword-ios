//
//  TableViewCellFutter.swift
//  RVG
//
//  Created by Charanbir Sandhu on 05/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class TableViewCellFutter: UITableViewCell {

    @IBOutlet weak var lblFutter: UILabel!
    @IBOutlet weak var lblName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setValues(row:Int){
        if language == "english"{
            lblName.text = "Thy word is a lamp unto my feet, and a light unto my path"
            lblFutter.text = "Psalm 119:105"
        }else{
            lblName.text = "Lámpara es a mis pies tu palabra, y lumbrera a mi camino"
            lblFutter.text = "Salmo 119:105"
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
