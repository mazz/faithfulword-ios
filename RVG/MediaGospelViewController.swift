import UIKit
import MBProgressHUD
import Moya
import L10n_swift

class MediaGospelViewController: BaseClass {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var songsBarRightButton: UIBarButtonItem!

    var gospelId : String? = nil
    var media : [Playable] = []
    var gospelType: GospelType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 40

        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: "").l10n())
            DDLogDebug("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate

        if let gospelId = self.gospelId {
            provider.request(.gospelsMedia(uuid: gospelId, offset: 1, limit: 50)) { result in
                DDLogDebug("gospelMedia: \(result)")
                switch result {
                case let .success(moyaResponse):
                    do {
                        try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                        let mediaGospelResponse: MediaGospelResponse = try moyaResponse.map(MediaGospelResponse.self)
                        DDLogDebug("mapped to moyaResponse: \(moyaResponse)")
                        
                        self.media = mediaGospelResponse.result
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.tableView.reloadData()
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

        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService_depr.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.songsBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.title = NSLocalizedString("Soul-winning", comment: "").l10n()
        
    }
    
    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService_depr.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
        }
    }
}

extension MediaGospelViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell {
            cell.selectionStyle = .none
            cell.songLabel?.text = self.media[indexPath.row].localizedName!

            cell.imageIconView.image = UIImage(named:"double_feetprint_icon_white")!

            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            PlaybackService_depr.sharedInstance().disposePlayback()
            PlaybackService_depr.sharedInstance().media = media
            PlaybackService_depr.sharedInstance().mediaIndex = indexPath.row
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
        }
    }
}

