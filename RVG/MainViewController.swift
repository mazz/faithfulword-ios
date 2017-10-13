//
//  MainViewController.swift
//  RVG
//

import UIKit
import MBProgressHUD
import MessageUI
import SafariServices
import Moya
import L10n_swift

class MainViewController: BaseClass, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var homeTitleLabel: UILabel!
    @IBOutlet weak var rightHomeButton: UIButton!
    @IBOutlet var booksRightBarButtonItem: UIBarButtonItem!
    
//    var bookIds : [Book] = []
    var books : [Book] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuBar: UIBarButtonItem!
    
    var tableRowsArray: [(String, UIImage)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MenuFooterTableViewCell
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.onLanguageChanged), name: .L10nLanguageChanged, object: nil
        )

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        tableView.register(UINib(nibName: "MainMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuTableViewCellID")
        tableView.register(UINib(nibName: "MainMenuFooterTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuFooterTableViewCellID")
        
        collectionView.register(UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookCollectionViewCellID")
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.init(displayP3Red: 195.0/255, green: 3.0/255, blue: 33.0/255, alpha: 1.0)
        
        self.navigationItem.leftBarButtonItem = menuBar
        
//        self.navigationItem.title = NSLocalizedString("Books", comment: "").l10n()
//        
//        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
//        loadingNotification.mode = MBProgressHUDMode.indeterminate
//        
//        let provider = MoyaProvider<KJVRVGService>()
//        
//        let errorClosure = { (error: Swift.Error) -> Void in
//            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: ""))
//            print("error: \(error)")
//            
//            DispatchQueue.main.async {
//                MBProgressHUD.hide(for: self.view, animated: true)
//            }
//        }
//        let languageIdentifier: String = Device.preferredLanguageIdentifier().l10n()
//        print("main languageIdentifier \(languageIdentifier)")
//        print("main L10n.shared.language \(L10n.shared.language)")
//
//        provider.request(.books(languageId: L10n.shared.language)) { result in
//            print("moya books: \(result)")
//            switch result {
//            case let .success(moyaResponse):
//                do {
//                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
//                    let data = moyaResponse.data
//                    var parsedObject: BookResponse
//                    
//                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
//                    if let jsonObject = json as? [String:Any] {
//                        parsedObject = BookResponse(JSON: jsonObject)!
//                        print(parsedObject)
//                        self.books = parsedObject.books!
//                        DispatchQueue.main.async {
//                            MBProgressHUD.hide(for: self.view, animated: true)
//                            self.collectionView.reloadData()
//                        }
//                    }
//                }
//                catch {
//                    errorClosure(error)
//                }
//                
//            case let .failure(error):
//                // this means there was a network failure - either the request
//                // wasn't sent (connectivity), or no response was received (server
//                // timed out).  If the server responds with a 4xx or 5xx error, that
//                // will be sent as a ".success"-ful response.
//                errorClosure(error)
//            }
//        }
        
    }
    
    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        refreshTitles()
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.booksRightBarButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.navigationItem.title = NSLocalizedString("Books", comment: "").l10n()
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        
        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: "").l10n())
            print("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        provider.request(.books(languageId: L10n.shared.language)) { result in
            print("moya books: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    var parsedObject: BookResponse
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let jsonObject = json as? [String:Any] {
                        parsedObject = BookResponse(JSON: jsonObject)!
                        print(parsedObject)
                        self.books = parsedObject.books!
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.collectionView.reloadData()
                        }
                    }
                }
                catch {
                    errorClosure(error)
                }
                
            case let .failure(error):
                // this means there was a network failure - either the request
                // wasn't sent (connectivity), or no response was received (server
                // timed out).  If the server responds with a 4xx or 5xx error, that
                // will be sent as a ".success"-ful response.
                errorClosure(error)
            }
        }
    }
    
    func refreshTitles() {
        self.tableRowsArray = [(NSLocalizedString("Books", comment: "").l10n(), UIImage(named: "books-stack-of-three")!),
                               (NSLocalizedString("Soul-winning", comment: "").l10n(), UIImage(named: "candlelight")!),
                               (NSLocalizedString("Music", comment: "").l10n(), UIImage(named: "discs_icon_white")!),
                               (NSLocalizedString("About Us", comment: "").l10n(), UIImage(named: "about_ic")!),
                               (NSLocalizedString("Share", comment: "").l10n(), UIImage(named: "share_ic")!),
                               (NSLocalizedString("Other Languages", comment: "").l10n(), UIImage(named: "language_menu")!),
                               (NSLocalizedString("Donate", comment: "").l10n(), UIImage(named: "donate")!),
                               (NSLocalizedString("Privacy Policy", comment: "").l10n(), UIImage(named: "privacy_ic")!),
                               (NSLocalizedString("Contact Us", comment: "").l10n(), UIImage(named: "mail")!),
        ]
        
        self.tableView.reloadData()

        self.navigationItem.title = NSLocalizedString("Books", comment: "").l10n()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layouts = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layouts?.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 50)
    }
    
    @objc func onLanguageChanged() {
        self.refreshTitles()
    }
    
    @IBAction func toggleMenu(_ sender: UIButton) {
        if leftConstraint.constant == 0{
            leftConstraint.constant = UIScreen.main.bounds.width*80/100
        }else{
            leftConstraint.constant = 0
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (nil) in
        }
    }
    
    func shareTextButton() {
        
        // text to share
        let text = NSLocalizedString("KJVRVG: https://itunes.apple.com/us/app/kjvrvg/id1234062829?ls=1&mt=8", comment: "").l10n()
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        mailComposerVC.setToRecipients(["info@kjvrvg.com"])
        mailComposerVC.setSubject("KJVRVG iOS \(appVersionString) App Feedback")
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Swift.Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableRowsArray?.count)! + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == (tableRowsArray?.count)! {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuFooterTableViewCellID") as? MainMenuFooterTableViewCell
            cell?.selectionStyle = .none
            cell?.backgroundColor = UIColor.clear
            cell?.verseBodyLabel.text = NSLocalizedString("I am the door: by me if any man enter in, he shall be saved, and shall go in and out, and find pasture.", comment: "").l10n()
            cell?.chapterAndVerseLabel.text = NSLocalizedString("-Jesus Christ (John 10:9)", comment: "").l10n()
            
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
        if indexPath.row == (tableRowsArray?.count)! {
            return
        }
        /*        if indexPath.row == 0 {
         let vc = self.pushVc(strBdName: "Main", vcName: "LanguageViewController")
         self.navigationController?.pushViewController(vc, animated: true)
         }
         else */
        if indexPath.row == 0 {
            // no action, just close menu
        }
        if indexPath.row == 1 {
            let vc = self.pushVc(strBdName: "Main", vcName: "GospelViewController")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 2 {
            let vc = self.pushVc(strBdName: "Main", vcName: "MusicViewController")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 3 {
            let svc = SFSafariViewController(url: NSURL(string: "http://kjvrvg.com/")! as URL)
            self.present(svc, animated: true, completion: nil)
        }
        else if indexPath.row == 4 {
            shareTextButton()
        }
        else if indexPath.row == 5 {
            let vc = self.pushVc(strBdName: "Main", vcName: "OtherLanguagesViewController") as! OtherLanguagesViewController
//            let videoURL = URL(fileURLWithPath:Bundle.main.path(forResource: "other-languages-sm", ofType: "m4v")!)
//            vc.looper = QueuePlayerLooper(videoURL: videoURL, loopCount: -1)
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 6 {
            
            UIApplication.shared.open(NSURL(string:"http://kjvrvg.com/donate/")! as URL, options: [:], completionHandler: nil)
            //            let svc = SFSafariViewController(url: NSURL(string: "http://kjvrvg.com/donate/")! as URL)
            //            self.present(svc, animated: true, completion: nil)
            
            //            let vc = self.pushVc(strBdName: "Main", vcName: "DonateViewController")
            //            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 7 {
            let svc = SFSafariViewController(url: NSURL(string: "http://kjvrvg.com/privacy-policy/")! as URL)
            self.present(svc, animated: true, completion: nil)
        }
        else if indexPath.row == 8 {
            let mailComposeViewController = configuredMailComposeViewController()
            if MFMailComposeViewController.canSendMail() {
                self.present(mailComposeViewController, animated: true, completion: nil)
            } else {
                self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Mail services are not available", comment: "").l10n())
            }
        }
        toggleMenu(UIButton())
    }
    
}

extension MainViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCollectionViewCellID", for: indexPath) as? BookCollectionViewCell
        
        if let localizedTitle = books[indexPath.row].localizedTitle {
            cell?.label.text = localizedTitle
            print("book at index: \(indexPath.row) \(localizedTitle)")
        }

        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reachability = Reachability()!
        
        if reachability.currentReachabilityStatus != .notReachable {
            if let bookId = books[indexPath.row].bookId {
                let vc = self.pushVc(strBdName: "Main", vcName: "ChapterViewController") as? ChapterViewController
                //            vc?.folderId = id
                vc?.bookId = bookId
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        } else {
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Your device is not connected to the Internet.", comment: "").l10n())
        }
        
    }
}
