//
//  MusicViewController.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD

class MusicViewController: BaseClass {
    @IBOutlet var musicBarRightButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    var musicIds: [Music] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Music", comment: "")
        
        do {
//            if let _ = bookId {
                // "e931ea58-080f-46ee-ae21-3bbec0365ddc"
                
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            //        loadingNotification.label.text = "Loading"
            
            try BibleService.sharedInstance().getMusic(success: { (music) in
                if let returnedMusic = music {
                    self.musicIds = returnedMusic
                    print("got musicIds: \(self.musicIds)")
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableView.reloadData()
                    }
                }
            })
//            }
            
        } catch let error {
            print("failed getting music: \(error)")
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem getting the media.", comment: ""))
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableView.reloadData()
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
            self.present(viewController, animated: true, completion: { _ in })
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
