import UIKit
import MBProgressHUD
import Moya
import L10n_swift

enum GospelType {
    case planOfSalvation
    case soulwinningMotivation
}

class GospelViewController: BaseClass {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var songsBarRightButton: UIBarButtonItem!

    var gospelId : String? = nil
    var gospels : [Gospel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40

//        self.title = NSLocalizedString("Gospel", comment: "").l10n()
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
//        
//        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
//        loadingNotification.mode = MBProgressHUDMode.indeterminate
//
//        provider.request(.gospels(languageId: Device.preferredLanguageIdentifier())) { result in
//            print("gospels: \(result)")
//            switch result {
//            case let .success(moyaResponse):
//                do {
//                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
//                    let data = moyaResponse.data
//                    var parsedObject: GospelResponse
//                    
//                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
//                    if let jsonObject = json as? [String:Any] {
//                        parsedObject = GospelResponse(JSON: jsonObject)!
//                        print(parsedObject)
//                        
//                        self.gospels = parsedObject.gospels!
//                        DispatchQueue.main.async {
//                            MBProgressHUD.hide(for: self.view, animated: true)
//                            self.tableView.reloadData()
//                        }
//                        
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
        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.songsBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.title = NSLocalizedString("Gospel", comment: "").l10n()
        
        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: "").l10n())
            print("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        
        provider.request(.gospels(languageId: L10n.shared.language)) { result in
            print("gospels: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    var parsedObject: GospelResponse
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let jsonObject = json as? [String:Any] {
                        parsedObject = GospelResponse(JSON: jsonObject)!
                        print(parsedObject)
                        
                        self.gospels = parsedObject.gospels!
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
            self.present(viewController, animated: true, completion: { _ in })
        }
    }
}

extension GospelViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gospels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell {
            cell.selectionStyle = .none
            cell.songLabel?.text = self.gospels[indexPath.row].localizedTitle!
            cell.imageIconView.image = (indexPath.row == 0) ? UIImage(named:"candlelight")! : UIImage(named:"feetprint")! 
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reachability = Reachability()!
        
        if reachability.currentReachabilityStatus != .notReachable {
            if let gospelId = gospels[indexPath.row].gospelId {
                let vc = self.pushVc(strBdName: "Main", vcName: "MediaGospelViewController") as? MediaGospelViewController
                vc?.gospelId = gospelId
                vc?.gospelType = (indexPath.row == 0) ? .planOfSalvation : .soulwinningMotivation
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        } else {
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Your device is not connected to the Internet.", comment: "").l10n())
        }
    }
}

