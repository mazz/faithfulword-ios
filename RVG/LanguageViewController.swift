//
//  LanguageViewController.swift
//  RVG
//
//  Created by maz on 2017-06-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit
import MBProgressHUD

class LanguageViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let textCellIdentifier = "TextCell"
    var languageIdentifiers : [LanguageIdentifier]  = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Language", comment: "").l10n()
//        self.navigationController?.isNavigationBarHidden=false
        
        do {
//            if let _ = bookId {
                // "e931ea58-080f-46ee-ae21-3bbec0365ddc"
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                //        loadingNotification.label.text = "Loading"
                
                
            try BibleService.sharedInstance().getSupportedLanguageIdentifiers(success: { (languageIdentifiers) in
                print("got languageIdentifiers: \(String(describing: languageIdentifiers))")
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.languageIdentifiers = languageIdentifiers!
                    self.tableView.reloadData()
                }
            })
            
            /*
                try BibleService.sharedInstance().getMediaChapters(forBookId: bookId!, success: { (media) in
                    print("got media: \(String(describing: media))")
                    self.media = media!
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tableVw.reloadData()
                    }
                })
 */
//            }
            
        } catch {
            print("failed getting language identifiers")
        }
        
        
        
        //getSupportedLanguageIdentifiers
        
    }

}

extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.languageIdentifiers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style:UITableViewCellStyle.subtitle, reuseIdentifier:textCellIdentifier)
        let row = indexPath.row
        
        cell.textLabel?.text = (Locale.current as NSLocale).displayName(forKey:NSLocale.Key.identifier, value: languageIdentifiers[row].languageIdentifier!)?.capitalized
        cell.textLabel?.textColor = UIColor.white
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
    }
    /*
    
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
 */
}
