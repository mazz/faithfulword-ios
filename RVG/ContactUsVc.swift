//
//  ContactUsVc.swift
//  RVG
//  
//  Created by Charanbir Sandhu on 05/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class ContactUsVc: BaseClass {

    @IBOutlet weak var lblSubmit: UIButton!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblName: UILabel!
    let objModel = ModelContactUs()
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtMessage: UITextView!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnSubmit.layer.borderColor = UIColor.white.cgColor
        // Do any additional setup after loading the view.
        if language == "english"{
            self.title = "Contact Us"
            lblSubmit.setTitle("Submit", for: .normal)
            lblName.text = "Name"
            lblEmail.text = "Email"
            lblMessage.text = "Message"
        }else{
            self.title = "Contáctenos"
            lblName.text = "Nombre"
            lblEmail.text = "correo electrónico"
            lblMessage.text = "Mensaje"
            lblSubmit.setTitle("Enviar", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func btnSubmit(_ sender: AnyObject) {
        ContactUsBusinessLogicClass().checkValidations(obj: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ContactUsVc : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}
