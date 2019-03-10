
import UIKit
import MBProgressHUD
import Moya

class MediaMusicViewController: BaseClass {

    var musicId : String? = nil
    var musicTitle : String? = nil
    var music : [MediaMusic] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var musicBarRightButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = (musicTitle! != nil) ? musicTitle! : NSLocalizedString("Music", comment: "")
        
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
        
        provider.request(.musicMedia(uuid: musicId!, offset: 1, limit: 50) ) { result in
            DDLogDebug("gospels: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let mediaMusicResponse: MediaMusicResponse = try moyaResponse.map(MediaMusicResponse.self)
                    DDLogDebug("mapped to moyaResponse: \(moyaResponse)")
                    
                    self.music = mediaMusicResponse.result
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
        
                tableView.register(UINib(nibName: "MediaMusicTableViewCell", bundle: nil), forCellReuseIdentifier: "MediaMusicTableViewCellID")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService_depr.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.musicBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService_depr.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
        }
    }

}

extension MediaMusicViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.music.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MediaMusicTableViewCellID") as? MediaMusicTableViewCell
        cell?.selectionStyle = .none
        cell?.songLabel?.text = self.music[indexPath.row].localizedName!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            //            let media = tableRows.map({$0.url})
            
            PlaybackService_depr.sharedInstance().disposePlayback()
            PlaybackService_depr.sharedInstance().media = music
            PlaybackService_depr.sharedInstance().mediaIndex = indexPath.row
            //            PlaybackService.sharedInstance().playbackModeDelegate = self
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: nil)
            
            //            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

