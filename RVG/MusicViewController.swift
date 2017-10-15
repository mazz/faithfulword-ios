//
//  MusicViewController.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD
import Moya

class MusicViewController: BaseClass {
    @IBOutlet var musicBarRightButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    var musicIds: [Music] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Music", comment: "")

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
        
        provider.request(.music) { result in
            print("gospels: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    var parsedObject: MusicResponse
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let jsonObject = json as? [String:Any] {
                        parsedObject = MusicResponse(JSON: jsonObject)!
                        print(parsedObject)
                        
                        self.musicIds = parsedObject.music!
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
        
        tableView.register(UINib(nibName: "MusicTableViewCell", bundle: nil), forCellReuseIdentifier: "MusicTableViewCellID")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.musicBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
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

extension MusicViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.musicIds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicTableViewCellID") as? MusicTableViewCell
        cell?.selectionStyle = .none
        cell?.titleLabel?.text = self.musicIds[indexPath.row].title!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reachability = Reachability()!

        if reachability.currentReachabilityStatus != .notReachable {
            if let musicId = musicIds[indexPath.row].musicId {
                let vc = self.pushVc(strBdName: "Main", vcName: "MediaMusicViewController") as? MediaMusicViewController
                //            vc?.folderId = id
                vc?.musicId = musicId
                vc?.musicTitle = musicIds[indexPath.row].title
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        } else {
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("Your device is not connected to the Internet.", comment: ""))
        }
    }
}
