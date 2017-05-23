//
//  MainViewController.swift
//  RVG
//

import UIKit
import MBProgressHUD

class MainViewController: BaseClass {

    @IBOutlet weak var lblHome: UILabel!
    @IBOutlet weak var btnPlayer: UIButton!
    @IBOutlet weak var lblRVG2010: UILabel!
    static var shareInstance : MainViewController?
    
    var arrOfFolders : [ModelOfViewControllerFolders] = []
    var bookIds : [Book] = []
    
    let objMainViewControllerBusinessLogicClass : MainViewControllerBusinessLogicClass? = MainViewControllerBusinessLogicClass()
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
    
    var bookTitles: [String] = [NSLocalizedString("Matthew", comment: ""),
                                NSLocalizedString("Mark", comment: ""),
                                NSLocalizedString("Luke", comment: ""),
                                NSLocalizedString("John", comment: ""),
                                NSLocalizedString("Acts", comment: ""),
                                NSLocalizedString("Romans", comment: ""),
                                NSLocalizedString("1 Corinthians", comment: ""),
                                NSLocalizedString("2 Corinthians", comment: ""),
                                NSLocalizedString("Galatians", comment: ""),
                                NSLocalizedString("Ephesians", comment: ""),
                                NSLocalizedString("Philippians", comment: ""),
                                NSLocalizedString("Colossians", comment: ""),
                                NSLocalizedString("1 Thessalonians", comment: ""),
                                NSLocalizedString("2 Thessalonians", comment: ""),
                                NSLocalizedString("1 Timothy", comment: ""),
                                NSLocalizedString("2 Timothy", comment: ""),
                                NSLocalizedString("Titus", comment: ""),
                                NSLocalizedString("Philemon", comment: ""),
                                NSLocalizedString("Hebrews", comment: ""),
                                NSLocalizedString("James", comment: ""),
                                NSLocalizedString("1 Peter", comment: ""),
                                NSLocalizedString("2 Peter", comment: ""),
                                NSLocalizedString("1 John", comment: ""),
                                NSLocalizedString("2 John", comment: ""),
                                NSLocalizedString("3 John", comment: ""),
                                NSLocalizedString("Jude", comment: ""),
                                NSLocalizedString("Revelation", comment: ""),
                                NSLocalizedString("Plan Of Salvation", comment: ""),
                                ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // MenuFooterTableViewCell

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40

        tableView.register(UINib(nibName: "MainMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuTableViewCellID")
        tableView.register(UINib(nibName: "MainMenuFooterTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuFooterTableViewCellID")

//        collectionView.register(nib: UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookCollectionViewCellID")
        collectionView.register(UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookCollectionViewCellID")
//        (UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellReuseIdentifier: "BookCollectionViewCellID")
        
        MainViewController.shareInstance=self
        btnBlur.isHidden=true
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.init(displayP3Red: 195.0/255, green: 3.0/255, blue: 33.0/255, alpha: 1.0)
        
        self.navigationItem.leftBarButtonItem = menuBar
        
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
//        loadingNotification.label.text = "Loading"
        objMainViewControllerBusinessLogicClass?.hitWebService(obj: self)

        
        if Bible.sharedInstance().books == nil {
            do {
                try BibleService.sharedInstance().getBooks(success: { (books) in
                    Bible.sharedInstance().books = books
                    
                    print(Bible.sharedInstance().books! as [Book])
                    
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.bookIds = Bible.sharedInstance().books!
                        self.collectionView.reloadData()
                    }
                    
                })
            } catch {
                print("error: \(error)")
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }

            }
        } else {
            self.collectionView.reloadData()
        }

        
        if (UserDefaults.standard.value(forKey: isFirstTime) as? String) == nil {
            DispatchQueue.main.async {
                let vc = self.pushVc(strBdName: "Main", vcName: "ChangeLanguageViewController")
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    @IBAction func btnPlayer(_ sender: AnyObject) {
        if let vc = PlayerViewController.shareInstance{
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
        lblHome.text = NSLocalizedString("Books", comment: "")

        if PlayerViewController.shareInstance != nil{
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
        let text = NSLocalizedString("The need is great, the means are available, and there could be no greater time needed to hear this powerful reading of the Word of God. Listen to Bro Domonique Davis' Fire Breathing Reading (coming soon!) Listen to Bro Collin Schneide in the first ever RVG Audio NT Check our page out and donate to our cause! The need is great, the means are available, and there could be no greater time needed to hear the powerful reading of the Word of God. \n https://itunes.apple.com/us/app/rvg/id1217019384?ls=1&mt=8", comment: "")
        
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuFooterTableViewCellID") as? MainMenuFooterTableViewCell
            cell?.selectionStyle = .none
            cell?.backgroundColor = UIColor.clear
            cell?.verseBodyLabel.text = NSLocalizedString("Thy word is a lamp unto my feet, and a light unto my path", comment: "")
            cell?.chapterAndVerseLabel.text = NSLocalizedString("Psalm 119:105", comment: "")

            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuTableViewCellID") as? MainMenuTableViewCell
            cell?.backgroundColor = UIColor.clear
            cell?.selectionStyle = .none
            cell?.label.text = tableRowsArray?[indexPath.row].0
            cell?.iconView.image = tableRowsArray?[indexPath.row].1
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 7 {
            return
        }
        if indexPath.row == 0 {
//            objMainViewControllerBusinessLogicClass?.hitWebService(obj: self)
        }
        if indexPath.row == 1 {
            let vc = self.pushVc(strBdName: "Main", vcName: "AboutUsViewController")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 2 {
            shareTextButton()
        }
        else if indexPath.row == 3 {
            let vc = self.pushVc(strBdName: "Main", vcName: "ChangeLanguageViewController")
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
            let vc = self.pushVc(strBdName: "Main", vcName: "ContactUsViewController")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        menuBtn(UIButton())
    }
}

extension MainViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookTitles.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCollectionViewCellID", for: indexPath) as? BookCollectionViewCell
//        cell?.setData(obj: arrOfFolders[indexPath.row])
        cell?.label.text = bookTitles[indexPath.row]
        
        print("book at index: \(indexPath.row) \(self.bookTitles[indexPath.row])")
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let id = arrOfFolders[indexPath.row].id {
            let vc = self.pushVc(strBdName: "Main", vcName: "SongsViewController") as? SongsViewController
            vc?.folderId = id
            self.navigationController?.pushViewController(vc!, animated: true)
        }
    }
}

