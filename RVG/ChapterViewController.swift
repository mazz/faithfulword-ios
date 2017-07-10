//
//  SongsViewController.swift
//  RVG
//

import UIKit
import MBProgressHUD

class ChapterViewController: BaseClass {
    @IBOutlet var songsBarRightButton: UIBarButtonItem!
    
    var bookId : String? = nil
    var media : [MediaChapter] = []

    @IBOutlet weak var tableVw: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Chapters", comment: "")
        
        do {
            if let _ = bookId {
                // "e931ea58-080f-46ee-ae21-3bbec0365ddc"
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                //        loadingNotification.label.text = "Loading"

                try BibleService.sharedInstance().getMediaChapters(forBookId: bookId!, success: { (media) in
                    print("got media: \(String(describing: media))")
                    self.media = media!
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableVw.reloadData()
                    }
                })
            }
            
        } catch let error {
            print("failed getting media: \(error)")
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableVw.reloadData()
            }
        }
        
        tableVw.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")

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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}

extension ChapterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell
        cell?.selectionStyle = .none
        cell?.songLabel?.text = self.media[indexPath.row].localizedName!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
//            let media = tableRows.map({$0.url})
            
            PlaybackService.sharedInstance().disposePlayback()
            PlaybackService.sharedInstance().media = media
            PlaybackService.sharedInstance().mediaIndex = indexPath.row
//            PlaybackService.sharedInstance().playbackModeDelegate = self
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
            
            //            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
