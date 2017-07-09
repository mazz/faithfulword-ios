//
//  GospelViewController.swift
//  RVG
//
//  Created by maz on 2017-06-08.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD

class GospelViewController: UIViewController {
    @IBOutlet var rightButtonPlayer: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var gospelId : String? = nil
    var media : [MediaGospel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController?.isNavigationBarHidden=false
        
        self.title = NSLocalizedString("Gospel", comment: "")
        
        do {
            if let _ = gospelId {
                // "e931ea58-080f-46ee-ae21-3bbec0365ddc"
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                //        loadingNotification.label.text = "Loading"
                
                try BibleService.sharedInstance().getMediaGospels(forGospelId: gospelId!, success: { (media) in
                    print("got media gospel: \(String(describing: media))")
                    self.media = media!
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableView.reloadData()
                    }
                })
            }
            
        } catch {
            print("failed getting media")
        }
        
        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "SongTableViewCellID")
        
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
