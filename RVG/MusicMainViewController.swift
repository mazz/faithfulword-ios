//
//  MusicMainViewController.swift
//  RVG
//
//  Created by maz on 2017-07-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD

class MusicMainViewController: BaseClass {
    @IBOutlet var musicBarRightButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    var music : [Music] = []

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
                    self.music = returnedMusic
                    print("got music: \(self.music)")
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableView.reloadData()
                    }
                }
            })
//            }
            
        } catch let error {
            print("failed getting music: \(error)")
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableView.reloadData()
            }
        }
        
        tableView.register(UINib(nibName: "MusicTableViewCell", bundle: nil), forCellReuseIdentifier: "MusicTableViewCellID")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MusicMainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.music.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicTableViewCellID") as? MusicTableViewCell
        cell?.selectionStyle = .none
        cell?.titleLabel?.text = self.music[indexPath.row].title!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "MediaMusicViewController") as? PlayerContainerViewController {
            
            //            let media = tableRows.map({$0.url})
            
//            PlaybackService.sharedInstance().disposePlayback()
//            PlaybackService.sharedInstance().media = media
//            PlaybackService.sharedInstance().mediaIndex = indexPath.row
            //            PlaybackService.sharedInstance().playbackModeDelegate = self
            
//            viewController.modalTransitionStyle = .crossDissolve
//            self.present(viewController, animated: true, completion: { _ in })
            
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
