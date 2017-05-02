//
//  VcTableViewCell.swift
//  RVG
//
//  Created by Charanbir Sandhu on 28/02/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class VcTableViewCell: UITableViewCell {

    @IBOutlet weak var imgVw: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setValues(row:Int){
        if language == "english"{
            if(row==0){
                lbl.text = "Books"
                imgVw.image = #imageLiteral(resourceName: "books-stack-of-three")
            }else if row==1{
                lbl.text = "About Us"
                imgVw.image = #imageLiteral(resourceName: "about_ic")
            }else if row==4{
                lbl.text = "Privacy Policy"
                imgVw.image = #imageLiteral(resourceName: "privacy_ic")
            }else if row==5{
                lbl.text = "Contact Us"
                imgVw.image = #imageLiteral(resourceName: "mail")
            }else if row==3{
                lbl.text = "Change Language"
                imgVw.image = #imageLiteral(resourceName: "language_180")
            }else if row==2{
                lbl.text = "Share"
                imgVw.image = #imageLiteral(resourceName: "share_ic")
            }
        }else{
            if(row==0){
                lbl.text = "Libros"
                imgVw.image = #imageLiteral(resourceName: "books-stack-of-three")
            }else if row==1{
                lbl.text = "Información de nosotros"
                imgVw.image = #imageLiteral(resourceName: "about_ic")
            }else if row==4{
                lbl.text = "Política de privacidad"
                imgVw.image = #imageLiteral(resourceName: "privacy_ic")
            }else if row==5{
                lbl.text = "Contáctenos"
                imgVw.image = #imageLiteral(resourceName: "mail")
            }else if row==3{
                lbl.text = "Cambiar idioma"
                imgVw.image = #imageLiteral(resourceName: "language_180")
            }else if row==2{
                lbl.text = "Compartir"
                imgVw.image = #imageLiteral(resourceName: "share_ic")
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
