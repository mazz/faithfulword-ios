//
//  SongVcBusinessLogicClass.swift
//  RVG
//
//  Created by Charanbir Sandhu on 01/03/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class SongVcBusinessLogicClass {

    func hitWebService(obj:SongsVc){
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
    
    func checkViewController(obj:SongsVc,row:Int){
        let vc = obj.pushVc(strBdName: "Main", vcName: "playerVc") as? playerVc
        vc?.objSongsModel=[]
        vc?.objSongsModel = obj.arrOfSongs
        vc?.index=row
        obj.navigationController?.pushViewController(vc!, animated: false)
    }

}
