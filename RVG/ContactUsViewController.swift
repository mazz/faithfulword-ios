//
//  ContactUsViewController.swift
//  RVG
//  

import UIKit

class ContactUsViewController: BaseClass {

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
        self.title = NSLocalizedString("Contact Us", comment: "")
        lblSubmit.setTitle(NSLocalizedString("Submit", comment: ""), for: .normal)
        lblName.text = NSLocalizedString("Name", comment: "")
        lblEmail.text = NSLocalizedString("Email", comment: "")
        lblMessage.text = NSLocalizedString("Message", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }
/*
    @IBAction func btnSubmit(_ sender: AnyObject) {
        let contactUs: ContactUsModel = ContactUsModel(name: "test name", email: "test@email.com", message: "test message", signup: false)
        
        do {
            try BibleService.sharedInstance().postContactUs(contactUsModel: contactUs) { (Void) in
                
                DispatchQueue.main.async {
                    print("contact us success")
                    self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Thank you, we will contact you soon", comment: ""))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                    
                }
            }
        } catch  {
            print("contact us error: \(error)")
        }

    }
*/
}


extension ContactUsViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}
