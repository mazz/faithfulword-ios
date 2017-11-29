
import UIKit
import Moya
import MBProgressHUD
import L10n_swift

class OtherLanguagesViewController: BaseClass {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var songsBarRightButton: UIBarButtonItem!
    
    var languages: [LanguageIdentifier] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.onLanguageChanged), name: .L10nLanguageChanged, object: nil
        )

        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.songsBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
        self.navigationItem.title = NSLocalizedString("Set Bible Language", comment: "").l10n()

        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the media.", comment: "").l10n())
            print("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        
        provider.request(.languagesSupported) { result in
            print("languagesSupported: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    var parsedObject: LanguagesSupportedResponse
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let jsonObject = json as? [String:Any] {
                        parsedObject = LanguagesSupportedResponse(JSON: jsonObject)!
                        print(parsedObject)
                        
                        self.languages = parsedObject.languageIdentifiers!
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.tableView.reloadData()
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
    
    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
        }
    }
}

extension OtherLanguagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell {
            cell.selectionStyle = .none
            
//            let languageID = Bundle.main.preferredLocalizations[0]// [[NSBundle mainBundle] preferredLocalizations].firstObject;
//            let locale = NSLocale(localeIdentifier: languageID)
//            let localizedString = locale.displayName(forKey: NSLocale.Key.identifier, value: self.languages[indexPath.row].languageIdentifier!)
            if let languageIdentifier = self.languages[indexPath.row].languageIdentifier {
                cell.songLabel?.text = self.localizedString(identifier: languageIdentifier)
                cell.imageIconView.image = UIImage(named: "language_menu")!
                
                if L10n.shared.language == languageIdentifier {
                    cell.customAccessory.isHidden = false
                    cell.customAccessory.image = UIImage(named: "check")
                } else {
                    cell.customAccessory.isHidden = true
                }
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let languageIdentifier = self.languages[indexPath.row].languageIdentifier {
            print("L10n.preferredLanguage: \(L10n.preferredLanguage)")
            print("L10n.supportedLanguages: \(L10n.supportedLanguages)")
            print("Bundle.main.preferredLocalizations: \(Bundle.main.preferredLocalizations)")

            L10n.shared.language = languageIdentifier
//            L10n.preferredLanguage = languageIdentifier
            
            print("L10n.preferredLanguage: \(L10n.preferredLanguage)")
            print("L10n.shared.language: \(L10n.shared.language)")
            print("languageIdentifier: \(languageIdentifier)")
    }
        

//
        
//        let reachability = Reachability()!
//
//        if reachability.currentReachabilityStatus != .notReachable {
//            if let gospelId = languages[indexPath.row].gospelId {
//                let vc = self.pushVc(strBdName: "Main", vcName: "MediaGospelViewController") as? MediaGospelViewController
//                vc?.gospelId = gospelId
//                vc?.gospelType = (indexPath.row == 0) ? .planOfSalvation : .soulwinningMotivation
//                self.navigationController?.pushViewController(vc!, animated: true)
//            }
//        } else {
//            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Your device is not connected to the Internet.", comment: ""))
//        }
    }
    
    func localizedString(identifier: String) -> String {
        let languageID = Bundle.main.preferredLocalizations[0]// [[NSBundle mainBundle] preferredLocalizations].firstObject;
        let locale = NSLocale(localeIdentifier: languageID)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: identifier)!
    }
    
    @objc func onLanguageChanged() {
        self.navigationController?.setViewControllers(
            self.navigationController?.viewControllers.map {
                if let storyboard = $0.storyboard, let identifier = $0.restorationIdentifier {
                    self.navigationItem.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
                    self.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
                    return storyboard.instantiateViewController(withIdentifier: identifier)
                }
                return $0
                } ?? [],
            animated: false
        )
    }
}


