//
//  SongsVc.swift
//  RVG
//
//  Created by Charanbir Sandhu on 01/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class SongsVc: BaseClass {

    static var shareInstance : SongsVc? = nil
    @IBOutlet var btnRightPlayer: UIBarButtonItem!
    var arrOfSongs : [ModelSongClass] = []
    let objSongVcBusinessLogicClass : SongVcBusinessLogicClass? = SongVcBusinessLogicClass()
    var folderId : String? = nil
    @IBOutlet weak var tableVw: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden=false
        SongsVc.shareInstance=self
        if folderId != nil{
            objSongVcBusinessLogicClass?.hitWebService(obj: self)
        }
        if language == "english"{
            self.title = "Chapters"
        }else{
            self.title = "Capítulos"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if playerVc.shareInstance != nil{
            self.navigationItem.rightBarButtonItem=btnRightPlayer
        }else{
            self.navigationItem.rightBarButtonItem=nil
        }
        self.navigationController?.isNavigationBarHidden=false
    }
    @IBAction func btnPlayer(_ sender: AnyObject) {
        if let vc = playerVc.shareInstance{
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

extension SongsVc: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrOfSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? SongCellTableViewCell
        cell?.selectionStyle = .none
        cell?.setValues(arrOfSongs[indexPath.row])
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = playerVc.shareInstance{
            if (self.navigationController?.viewControllers.contains(vc))!{
                var array = self.navigationController?.viewControllers
                let index = array?.index(of: vc)
                print(index)
                vc.objSongsModel = self.arrOfSongs
                vc.index=indexPath.row
                array?.remove(at: index!)
                array?.append(vc)
                self.navigationController?.viewControllers = array!
            }else{
                objSongVcBusinessLogicClass?.checkViewController(obj: self, row: indexPath.row)
            }
        }else{
            objSongVcBusinessLogicClass?.checkViewController(obj: self, row: indexPath.row)
        }
    }
}
