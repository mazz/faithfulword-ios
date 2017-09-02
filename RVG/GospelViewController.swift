//
//  GospelViewController.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD
import Moya

class GospelViewController: BaseClass {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var songsBarRightButton: UIBarButtonItem!

    var gospelId : String? = nil
    var media : [Playable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Plan of Salvation", comment: "")

        let provider = MoyaProvider<KJVRVGService>()
        
        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: ""))
            print("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate

        provider.request(.gospelMedia) { result in
            print("gospelMedia: \(result)")
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
                        
                        self.media = parsedObject.gospels!
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

extension GospelViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell {
            cell.selectionStyle = .none
            cell.songLabel?.text = self.media[indexPath.row].localizedName!
            cell.imageIconView.image = UIImage(named:"candlelight")!
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            PlaybackService.sharedInstance().disposePlayback()
            PlaybackService.sharedInstance().media = media
            PlaybackService.sharedInstance().mediaIndex = indexPath.row
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
        }
    }
}

