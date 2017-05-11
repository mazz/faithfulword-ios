//
//  SongsViewControllerBusinessLogicClass.swift
//  RVG
//

import UIKit

class SongsViewControllerBusinessLogicClass {

    func hitWebService(obj:SongsViewController){
        WebServiceSingleTon().getRequest(linkUrl: getFolders+obj.folderId!, indicator: true, success: { (data) in
            print(data)
            if data.count>0{
                obj.arrOfSongs.removeAll()
                for i in 0..<data.count{
                    if let dic = data[i] as? [String:AnyObject]{
                        let object = ModelSongClass()
                        object.setModelValues(dictionary: dic)
                        obj.arrOfSongs.append(object)
                    }
                }
                obj.tableVw.reloadData()
            }
        }) { (err) in
            obj.showSingleButtonAlertWithoutAction(title: err)
        }
    }
    
    func checkViewController(obj:SongsViewController,row:Int){
        let vc = obj.pushVc(strBdName: "Main", vcName: "PlayerViewController") as? PlayerViewController
        vc?.objSongsModel=[]
        vc?.objSongsModel = obj.arrOfSongs
        vc?.index=row
        obj.navigationController?.pushViewController(vc!, animated: false)
    }

}
