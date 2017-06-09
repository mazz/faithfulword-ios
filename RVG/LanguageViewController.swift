//
//  LanguageViewController.swift
//  RVG
//
//  Created by maz on 2017-06-09.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit

class LanguageViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let textCellIdentifier = "TextCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Language", comment: "")
        self.navigationController?.isNavigationBarHidden=false

        // Do any additional setup after loading the view.
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

extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCellID") as? SongTableViewCell
//        cell?.selectionStyle = .none
//        cell?.songLabel?.text = self.media[indexPath.row].localizedName!
//        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) //dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath)
            let cell = UITableViewCell(style:UITableViewCellStyle.subtitle, reuseIdentifier:textCellIdentifier)
        let row = indexPath.row
        cell.textLabel?.text = "foo"
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
