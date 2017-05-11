//
//  AboutUsViewController.swift
//  RVG
//

import UIKit

class AboutUsViewController: BaseClass {

    @IBOutlet weak var txtVw: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        hitWebService()
        self.navigationController?.isNavigationBarHidden=false
//        if language == "english" {
        self.title = NSLocalizedString("About Us", comment: "")
//        }
//        else {
//            self.title = "Información de nosotros"
//        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }
    
    func hitWebService(){
        WebServiceSingleTon().getRequest(linkUrl: aboutUs, indicator: true, success: { (data) in
            print(data)
            if let array = data[0] as? [String:AnyObject]{
                if language == "english"{
                    if let text = array["contentInEnglish"] as? String{
                        self.txtVw.text=text
                    }
                }else{
                    if let text = array["contentInSpanish"] as? String{
                        self.txtVw.text=text
                    }
                }
                
            }
        }) { (err) in
            self.showSingleButtonAlertWithoutAction(title: err)
        }
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
