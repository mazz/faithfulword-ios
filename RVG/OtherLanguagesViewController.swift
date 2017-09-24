//
//  OtherLanguagesViewController.swift
//  RVG
//
//  Created by maz on 2017-06-01.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import Moya
import MBProgressHUD

class OtherLanguagesViewController: BaseClass {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var songsBarRightButton: UIBarButtonItem!
    
    var languages: [LanguageIdentifier] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Other Languages", comment: "")
        
        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the media.", comment: ""))
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
        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.songsBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
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
            
            let languageID = Bundle.main.preferredLocalizations[0]// [[NSBundle mainBundle] preferredLocalizations].firstObject;
            let locale = NSLocale(localeIdentifier: languageID)
            let localizedString = locale.displayName(forKey: NSLocale.Key.identifier, value: self.languages[indexPath.row].languageIdentifier!)
            cell.songLabel?.text = localizedString
            cell.imageIconView.image = UIImage(named: "language_menu")!
            cell.disclosure.isHidden = true
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
}


