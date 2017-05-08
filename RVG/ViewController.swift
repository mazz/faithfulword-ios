//
//  MainViewController.swift
//  RVG
//
//  Created by Charanbir Sandhu on 27/02/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class MainViewController: BaseClass {

    @IBOutlet weak var lblHome: UILabel!
    @IBOutlet weak var btnPlayer: UIButton!
    @IBOutlet weak var lblRVG2010: UILabel!
    static var shareInstance : MainViewController?
    var arrOfFolders : [ModelOfViewControllerFolders] = []
    let objViewControllerBusinessLogicClass : ViewControllerBusinessLogicClass? = ViewControllerBusinessLogicClass()
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnBlur: UIButton!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuBar: UIBarButtonItem!
    
    var tableRowsArray: [(String, UIImage)]? = [(NSLocalizedString("Books", comment: ""), UIImage(named: "books-stack-of-three")!),
                                               (NSLocalizedString("About Us", comment: ""), UIImage(named: "about_ic")!),
                                               (NSLocalizedString("Share", comment: ""), UIImage(named: "share_ic")!),
                                               (NSLocalizedString("Change Language", comment: ""), UIImage(named: "language_180")!),
                                               (NSLocalizedString("Donate", comment: ""), UIImage(named: "books-stack-of-three")!),
                                               (NSLocalizedString("Privacy Policy", comment: ""), UIImage(named: "privacy_ic")!),
                                               (NSLocalizedString("Contact Us", comment: ""), UIImage(named: "mail")!),
                                               ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTableViewCellID")
        
        MainViewController.shareInstance=self
        btnBlur.isHidden=true
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.init(displayP3Red: 195.0/255, green: 3.0/255, blue: 33.0/255, alpha: 1.0)
       self.navigationItem.leftBarButtonItem=menuBar
        objViewControllerBusinessLogicClass?.hitWebService(obj: self)
        if (UserDefaults.standard.value(forKey: isFirstTime) as? String) == nil{
            DispatchQueue.main.async {
                let vc = self.pushVc(strBdName: "Main", vcName: "ChangeLanguageVc")
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func btnPlayer(_ sender: AnyObject) {
        if let vc = playerVc.shareInstance{
            if (self.navigationController?.viewControllers.contains(vc))!{
                var array = self.navigationController?.viewControllers
                let index = array?.index(of: vc)
                array?.remove(at: index!)
                array?.append(vc)
                self.navigationController?.viewControllers = array!
            }
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if language == "english"{
            lblHome.text = "Books"
        }else{
            lblHome.text = "Libros"
        }
        if playerVc.shareInstance != nil{
            btnPlayer.isHidden=false
        }else{
            btnPlayer.isHidden=true
        }
        self.navigationController?.isNavigationBarHidden=true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layouts = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layouts?.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 50)
    }
    @IBAction func menuBtn(_ sender: UIButton) {
        if leftConstraint.constant == 0{
            btnBlur.isHidden=false
            leftConstraint.constant = UIScreen.main.bounds.width*80/100
        }else{
            btnBlur.isHidden=true
            leftConstraint.constant = 0
        }
        btnBlur.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, animations: { 
            self.view.layoutIfNeeded()
            }) { (nil) in
                self.btnBlur.isUserInteractionEnabled = true
        }
    }
    
     func shareTextButton() {
        
        // text to share
        let text = "The need is great, the means are available, and there could be no greater time needed to hear this powerful reading of the Word of God. Listen to Bro Domonique Davis' Fire Breathing Reading (coming soon!) Listen to Bro Collin Schneide in the first ever RVG Audio NT Check our page out and donate to our cause! The need is great, the means are available, and there could be no greater time needed to hear the powerful reading of the Word of God. \n https://itunes.apple.com/us/app/rvg/id1217019384?ls=1&mt=8"
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}

extension MainViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 7 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell1") as? TableViewCellFutter
            cell?.selectionStyle = .none
            cell?.setValues(row: indexPath.row)
            
            return cell!
        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? VcTableViewCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCellID") as? MenuTableViewCell
            cell?.backgroundColor = UIColor.clear
            cell?.selectionStyle = .none
            cell?.label.text = tableRowsArray?[indexPath.row].0
            cell?.iconView.image = tableRowsArray?[indexPath.row].1
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 7 {
            return 130
        }else{
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 7 {
            return
        }
        if indexPath.row == 0 {
            objViewControllerBusinessLogicClass?.hitWebService(obj: self)
        }
        else if indexPath.row == 1 {
            let vc = self.pushVc(strBdName: "Main", vcName: "AboutUsVc")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 2 {
            shareTextButton()
        }
        else if indexPath.row == 3 {
            let vc = self.pushVc(strBdName: "Main", vcName: "ChangeLanguageVc")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 4 {
            let vc = self.pushVc(strBdName: "Main", vcName: "DonateViewController")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 5 {
            let vc = self.pushVc(strBdName: "Main", vcName: "PrivacyPolicy")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 6 {
            let vc = self.pushVc(strBdName: "Main", vcName: "ContactUsVc")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        menuBtn(UIButton())
    }
}

extension MainViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrOfFolders.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CollectionViewCellVc
        cell?.setData(obj: arrOfFolders[indexPath.row])
        
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let id = arrOfFolders[indexPath.row].id{
            let vc = self.pushVc(strBdName: "Main", vcName: "SongsVc") as? SongsVc
            vc?.folderId = id
            self.navigationController?.pushViewController(vc!, animated: true)
        }
    }
}

