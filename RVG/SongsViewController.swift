//
//  SongsViewController.swift
//  RVG
//

import UIKit
import MBProgressHUD

class SongsViewController: BaseClass {
    @IBOutlet var songsBarRightButton: UIBarButtonItem!
    
    var bookId : String? = nil
    var media : [MediaChapter] = []

    @IBOutlet weak var tableVw: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden=false
        
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
            
        } catch {
            print("failed getting media")
        }
        
        tableVw.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "SongTableViewCellID")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if PlayerViewController.shareInstance != nil{
            self.navigationItem.rightBarButtonItem=songsBarRightButton
        }else{
            self.navigationItem.rightBarButtonItem=nil
        }
        self.navigationController?.isNavigationBarHidden=false
    }
    @IBAction func btnPlayer(_ sender: AnyObject) {
        if let vc = PlayerViewController.shareInstance{
            if (self.navigationController?.viewControllers.contains(vc))!{
                var array = self.navigationController?.viewControllers
                let index = array?.index(of: vc)
                array?.remove(at: index!)
                array?.append(vc)
                self.navigationController?.viewControllers = array!
            }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }

}

extension SongsViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCellID") as? SongTableViewCell
        cell?.selectionStyle = .none
        cell?.songLabel?.text = self.media[indexPath.row].localizedName!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let playerViewController = PlayerViewController.shareInstance {
            if (self.navigationController?.viewControllers.contains(playerViewController))! {
                var array = self.navigationController?.viewControllers
                let index = array?.index(of: playerViewController)
                print(index)
                playerViewController.media = self.media
                playerViewController.index=indexPath.row
                array?.remove(at: index!)
                array?.append(playerViewController)
                self.navigationController?.viewControllers = array!
            } else {
//                objSongBusinessLogicClass?.checkViewController(obj: self, row: indexPath.row)

                let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController
                
//                let vc = obj.pushVc(strBdName: "Main", vcName: "PlayerViewController") as? PlayerViewController
//                viewController?.objSongsModel = []
                viewController?.media = self.media

                viewController?.index = indexPath.row
                self.navigationController?.pushViewController(viewController!, animated: false)

            }
        } else {
//            objSongBusinessLogicClass?.checkViewController(obj: self, row: indexPath.row)
            let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController
            
            //                let vc = obj.pushVc(strBdName: "Main", vcName: "PlayerViewController") as? PlayerViewController

            viewController?.media = self.media

            viewController?.index = indexPath.row
            self.navigationController?.pushViewController(viewController!, animated: false)

        }
    }
}
