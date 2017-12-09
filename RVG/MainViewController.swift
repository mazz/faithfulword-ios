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
import RxSwift
import UserNotifications
import Firebase

class MainViewController: BaseClass, MFMailComposeViewControllerDelegate, AppVersioning, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    @IBOutlet weak var homeTitleLabel: UILabel!
    @IBOutlet weak var rightHomeButton: UIButton!
    @IBOutlet var booksRightBarButtonItem: UIBarButtonItem!

    var books : [Book] = []
    
    private var didVersionCheck = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()
    private static var secondsInAWeek: TimeInterval {
        return TimeInterval(((60 * 24) * 60) * 7)
    }
    private static var lastVersionCheck = "lastVersionCheck"
    private static var lastPushNotificationCheck = "lastPushNotificationCheck"
    private static var monday = 1
    private static var saturday = 6
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuBar: UIBarButtonItem!
    
    var tableRowsArray: [(String, UIImage)]?
    
    func okAlert(action: UIAlertAction, _ alert:UIAlertController) {
        UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/kjvrvg/id1234062829?ls=1&mt=8")!, options: [:], completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.onLanguageChanged), name: .L10nLanguageChanged, object: nil
        )

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        tableView.register(UINib(nibName: "MainMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuTableViewCellID")
        tableView.register(UINib(nibName: "MainMenuFooterTableViewCell", bundle: nil), forCellReuseIdentifier: "MainMenuFooterTableViewCellID")
        
        collectionView.register(UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookCollectionViewCellID")
        
        self.navigationItem.leftBarButtonItem = menuBar
        
        didVersionCheck
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] didCheck in
            let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
            let dayNumberOfWeek = Calendar.current.component(.weekday, from: Date())
            
            let lastPushNotificationCheck: Date? = UserDefaults.standard.object(forKey: MainViewController.lastPushNotificationCheck) as? Date
            print("lastPushNotificationCheck: \(lastPushNotificationCheck)")
            print("isRegisteredForRemoteNotifications: \(isRegisteredForRemoteNotifications)")
            // if we never checked for push notifications opt-in yet, OR it's been at least a week since we last checked AND today is Saturday
            if lastPushNotificationCheck == nil || ((Date().timeIntervalSince1970 - (lastPushNotificationCheck?.timeIntervalSince1970)!) >  MainViewController.secondsInAWeek && dayNumberOfWeek == MainViewController.saturday) {
                if !isRegisteredForRemoteNotifications {
                    let alert = UIAlertController(title: NSLocalizedString("Notifications", comment: ""),
                                                  message: NSLocalizedString("Keep up with new sermons and content regularly!", comment: ""),
                                                  preferredStyle: .alert)
                    let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: ""), style: .cancel, handler: { (action) -> Void in
                        UserDefaults.standard.set(Date(), forKey: MainViewController.lastPushNotificationCheck)
                    })
                    let getNotifications = UIAlertAction(title: NSLocalizedString("Get Notifications", comment: ""), style: .default, handler: { (action) -> Void in
                        self.optInForPushNotifications(application: UIApplication.shared)
                    })
                    
                    alert.addAction(laterAction)
                    alert.addAction(getNotifications)
                    
                    self.present(alert, animated: false, completion: nil)
                }
            }

            }
            .disposed(by: disposeBag)
        
        appVersionCheck()
    }
    
    func optInForPushNotifications(application: UIApplication) {
        UserDefaults.standard.set(Date(), forKey: MainViewController.lastPushNotificationCheck)

        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
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
        
        self.navigationItem.title = NSLocalizedString("Bible", comment: "").l10n()
        
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
        self.tableRowsArray = [(NSLocalizedString("Bible", comment: "").l10n(), UIImage(named: "books-stack-of-three")!),
                               (NSLocalizedString("Soul-winning", comment: "").l10n(), UIImage(named: "candlelight")!),
                               (NSLocalizedString("Music", comment: "").l10n(), UIImage(named: "discs_icon_white")!),
                               (NSLocalizedString("About Us", comment: "").l10n(), UIImage(named: "about_ic")!),
                               (NSLocalizedString("Share", comment: "").l10n(), UIImage(named: "share_ic")!),
                               (NSLocalizedString("Set Bible Language", comment: "").l10n(), UIImage(named: "language_menu")!),
                               (NSLocalizedString("Donate", comment: "").l10n(), UIImage(named: "donate")!),
                               (NSLocalizedString("Privacy Policy", comment: "").l10n(), UIImage(named: "privacy_ic")!),
                               (NSLocalizedString("Contact Us", comment: "").l10n(), UIImage(named: "mail")!),
        ]
        
        self.tableView.reloadData()

        self.navigationItem.title = NSLocalizedString("Bible", comment: "").l10n()
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
        let allScripture = NSLocalizedString("All Scripture", comment: "")
        
        let text = NSLocalizedString("\(allScripture): https://itunes.apple.com/us/app/kjvrvg/id1234062829?ls=1&mt=8", comment: "").l10n()
        
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

        mailComposerVC.setToRecipients(["allscripturebaptist@gmail.com"])
        mailComposerVC.setSubject("All Scripture iOS \(appVersionString) App Feedback")
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Swift.Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func appVersionCheck() {
        let dayNumberOfWeek = Calendar.current.component(.weekday, from: Date())
        // 2 == Monday

        let lastVersionCheck: Date? = UserDefaults.standard.object(forKey: MainViewController.lastVersionCheck) as? Date
        
        print("Date().timeIntervalSince1970: \(Date().timeIntervalSince1970)")
        print("lastVersionCheck: \(lastVersionCheck)")

        if lastVersionCheck == nil || ((Date().timeIntervalSince1970 - (lastVersionCheck?.timeIntervalSince1970)!) >  MainViewController.secondsInAWeek && dayNumberOfWeek == MainViewController.monday) {
            let provider = MoyaProvider<KJVRVGService>()
            
            provider.request(.appVersions) { result in
                switch result {
                case let .success(moyaResponse):
                    do {
                        UserDefaults.standard.set(Date(), forKey: MainViewController.lastVersionCheck)

                        try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                        let data = moyaResponse.data
                        
                        let appVersionsResponse: AppVersionResponse = try moyaResponse.map(AppVersionResponse.self)
                        print("mapped to appVersionsResponse: \(appVersionsResponse)")
                        
                        var amISupported = false
                        var amICurrent = false
                        
                        let appVersions = appVersionsResponse.result
                        guard appVersions.count > 0 else {
                            self.didVersionCheck.onNext(false)
                            return
                        }
                        
                        let bundleVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                        
                        for (_, v) in appVersions.enumerated() {
                            if v.versionNumber == bundleVersion {
                                amISupported = v.iosSupported
                            }
                        }
                        print("amISupported: \(amISupported)")
                        
                        if let latestAppVersion = appVersions.last?.versionNumber {
                            if latestAppVersion == bundleVersion {
                                amICurrent = true
                            }
                        }
                        print("amICurrent: \(amICurrent)")
                        
                        if amICurrent == false {
                            let alert = UIAlertController(title: NSLocalizedString("Upgrade to New Version", comment: ""),
                                                          message: NSLocalizedString("There is a new version available", comment: ""),
                                                          preferredStyle: .alert)
                            let laterAction = UIAlertAction(title: NSLocalizedString("Upgrade Later", comment: ""), style: .cancel, handler: { (action) -> Void in
                                self.didVersionCheck.onNext(true)
                            })
                            
                            let appStore = UIAlertAction(title: NSLocalizedString("Go To App Store", comment: ""), style: .default, handler: { (action) -> Void in
                                UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/kjvrvg/id1234062829?ls=1&mt=8")!, options: [:], completionHandler: nil)
                            })
                            if amISupported == true {
                                alert.addAction(laterAction)
                            }
                            alert.addAction(appStore)
                            self.present(alert, animated: false, completion: nil)
                        } else {
                            print("amICurrent true, didVersionCheck.onNext(true)")
                            self.didVersionCheck.onNext(true)
                        }
                    }
                    catch {
                        self.didVersionCheck.onNext(false)
                        print("error: \(error)")
                    }
                    
                case let .failure(error):
                    // this means there was a network failure - either the request
                    // wasn't sent (connectivity), or no response was received (server
                    // timed out).  If the server responds with a 4xx or 5xx error, that
                    // will be sent as a ".success"-ful response.
                    print("error: \(error)")
                    self.didVersionCheck.onNext(false)
                }
            }
        } else {
            print("didVersionCheck.onNext(false)")
            self.didVersionCheck.onNext(false)
        }
    }
    
    func updatePushToken(fcmToken: String,
                         apnsToken: String,
                         preferredLanguage: String,
                         userAgent: String) {
        let provider = MoyaProvider<KJVRVGService>()
        // deviceUniqueIdentifier: String, apnsToken: String, fcmToken: String, nonce:
        provider.request(.pushTokenUpdate(fcmToken: fcmToken,
                                          apnsToken: apnsToken,
                                          preferredLanguage: preferredLanguage,
                                          userAgent: userAgent)) { result in
                                            switch result {
                                            case let .success(moyaResponse):
                                                do {
                                                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                                                    let data = moyaResponse.data
                                                    //                    var parsedObject: BookResponse
                                                    
                                                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                                                    print("json: \(json)")
                                                    if let jsonObject = json as? [String:Any] {
                                                        print("jsonObject: \(jsonObject)")
                                                    }
                                                }
                                                catch {
                                                    print("error: \(error)")
                                                }
                                                
                                            case let .failure(error):
                                                print(".failure: \(error)")
                                                // this means there was a network failure - either the request
                                                // wasn't sent (connectivity), or no response was received (server
                                                // timed out).  If the server responds with a 4xx or 5xx error, that
                                                // will be sent as a ".success"-ful response.
                                                //                errorClosure(error)
                                                print(".failure")
                                            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
        print("response.actionIdentifier: \(response.actionIdentifier)")
        //        Messaging.messaging().appDidReceiveMessage()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
}

extension MainViewController {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase didRefreshRegistrationToken token: \(fcmToken)")
        if let apnsToken = Messaging.messaging().apnsToken {
            let apnsTokenString = apnsToken.map { String(format: "%02X", $0) }.joined()
            self.updatePushToken(fcmToken: fcmToken,
                                 apnsToken: apnsTokenString,
                                 preferredLanguage: L10n.shared.preferredLanguage,
                                 userAgent: Device.userAgent())
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("messaging remoteMessage.appData: \(remoteMessage.appData)")
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
            cell?.verseBodyLabel.text = NSLocalizedString("All scripture is given by inspiration of God, and is profitable for doctrine, for reproof, for correction, for instruction in righteousness: That the man of God may be perfect, thoroughly furnished unto all good works.", comment: "").l10n()
            cell?.chapterAndVerseLabel.text = NSLocalizedString("2 Timothy 3:16-17", comment: "").l10n()
            
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
            let svc = SFSafariViewController(url: NSURL(string: "http://allscripturebaptist.com/")! as URL)
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
            
            UIApplication.shared.open(NSURL(string:"http://allscripturebaptist.com/donate/")! as URL, options: [:], completionHandler: nil)
            //            let svc = SFSafariViewController(url: NSURL(string: "http://kjvrvg.com/donate/")! as URL)
            //            self.present(svc, animated: true, completion: nil)
            
            //            let vc = self.pushVc(strBdName: "Main", vcName: "DonateViewController")
            //            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 7 {
            let svc = SFSafariViewController(url: NSURL(string: "http://allscripturebaptist.com/privacy-policy/")! as URL)
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
