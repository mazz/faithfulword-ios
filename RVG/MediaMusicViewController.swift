//
//  MusicMediaViewController.swift
//  RVG
//
//  Created by maz on 2017-07-10.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD

class MediaMusicViewController: BaseClass {

    var musicId : String? = nil
    var musicTitle : String? = nil
    var music : [MediaMusic] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var musicBarRightButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = (musicTitle! != nil) ? musicTitle! : NSLocalizedString("Music", comment: "")

        do {
            if let _ = musicId {
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                
                try BibleService.sharedInstance().getMediaMusic(forMusicId: musicId!, success: { (music) in
                    print("got media: \(String(describing: music))")
                    self.music = music!
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableView.reloadData()
                    }
                })
            }
            
        } catch let error {
            print("failed getting media: \(error)")
//            let errorMessage: String = NSLocalizedString("There was a problem getting the media.", comment: "") //.appending(" \(error)")
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem getting the media.", comment: ""))

            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableView.reloadData()
            }
        }
//        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")
        tableView.register(UINib(nibName: "MediaMusicTableViewCell", bundle: nil), forCellReuseIdentifier: "MediaMusicTableViewCellID")
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
            
            PlaybackService.sharedInstance().disposePlayback()
            PlaybackService.sharedInstance().media = music
            PlaybackService.sharedInstance().mediaIndex = indexPath.row
            //            PlaybackService.sharedInstance().playbackModeDelegate = self
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
            
            //            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

