//
//  ViewControllerBusinessLogicClass.swift
//  RVG
//
//  Created by Charanbir Sandhu on 28/02/17.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit

class ViewControllerBusinessLogicClass {

    func hitWebService(obj:MainViewController){
        WebServiceSingleTon().getRequest(linkUrl: getFolders, indicator: true, success: { (data) in
            print(data)
            if data.count>0{
                obj.arrOfFolders.removeAll()
                for i in 0..<data.count{
                    if let dic = data[i] as? [String:AnyObject]{
                        let object = ModelOfViewControllerFolders()
                        object.setModelValues(dictionary: dic)
                        obj.arrOfFolders.append(object)
                    }
                }
                obj.collectionView.reloadData()
            }
            }) { (err) in
                obj.showSingleButtonAlertWithoutAction(title: err)
        }
    }
}
