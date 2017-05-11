//
//  ChangeLanguageVc.swift
//  RVG
//

import UIKit

class ChangeLanguageVc: BaseClass {
    @IBOutlet weak var btnEnglish: UIButton!
    @IBOutlet weak var btnSpinish: UIButton!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var lblchangeLanguage: UILabel!
    
    var Lang  = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden=false
        btnSubmit.layer.borderColor=UIColor.white.cgColor
        
        if (UserDefaults.standard.value(forKey: isFirstTime) as? String) == nil{
            UserDefaults.standard.set("no", forKey: isFirstTime)
            UserDefaults.standard.synchronize()
            UserDefaults.standard.set("english", forKey: keyForSaveLanguage)
            language="english"
            UserDefaults.standard.synchronize()
            self.title = "Select Language"
            MainViewController.shareInstance?.tableView.reloadData()
            MainViewController.shareInstance?.collectionView.reloadData()
            }else{
            if language == "english"{
                lblchangeLanguage.text = "Select Your Language"
                self.title = "Change Language"
                btnEnglish.setTitle("English", for: .normal)
                btnSpinish.setTitle("Spanish", for: .normal)
                btnSubmit.setTitle("Continue", for: .normal)
                btnEnglish.setTitleColor(UIColor.red, for: .normal)
            }else{
                self.title = "Cambiar idioma"
                btnSpinish.setTitle("Español", for: .normal)
                lblchangeLanguage.text = "Elige tu idioma"
                btnSubmit.setTitle("Continuar", for: .normal)
                btnEnglish.setTitle("Inglés", for: .normal)
                btnSpinish.setTitleColor(UIColor.red, for: .normal)
            }
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
    }
    
    @IBAction func btnEnglish(_ sender: UIButton) {
        Lang="english"
        btnEnglish.setTitleColor(UIColor.red, for: .normal)
        btnSpinish.setTitleColor(UIColor.white, for: .normal)
    }
    
    @IBAction func btnSpinish(_ sender: AnyObject) {
        btnEnglish.setTitleColor(UIColor.white, for: .normal)
        btnSpinish.setTitleColor(UIColor.red, for: .normal)
        Lang="spinish"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }

    @IBAction func btnContinue(_ sender: AnyObject) {
        if Lang == ""{
            return
        }
        language=Lang
        MainViewController.shareInstance?.tableView.reloadData()
        MainViewController.shareInstance?.collectionView.reloadData()
        UserDefaults.standard.set(Lang, forKey: keyForSaveLanguage)
        UserDefaults.standard.synchronize()
        _ = self.navigationController?.popViewController(animated: true)
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
