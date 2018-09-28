//
//  LoadingIndicator.swift
//  DemoWebservices
//
//  Created by Igniva-ios-12 on 11/4/16.
//  Copyright © 2016 Igniva-ios-12. All rights reserved.
//

import UIKit

class LoadingIndicator : UIView {
    
    convenience init(frames:CGRect) {
        self.init(frame:CGRect.zero)
        self.frame=frames
        self.backgroundColor=UIColor.clear
        self.addSubview(addImage())
        self.addSubview(initilizeIndicator())
    }
    
    func addImage() -> UIImageView {
        let imgVw = UIImageView()
        imgVw.frame=self.frame
        imgVw.backgroundColor=UIColor.clear
      //  imgVw.alpha=0.7
        return imgVw
    }
    
    func initilizeIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style : UIActivityIndicatorView.Style.whiteLarge)
        indicator.layer.cornerRadius=indicator.bounds.width/2
//        indicator.layer.borderWidth=1
//        indicator.layer.borderColor=UIColor.white.cgColor
        indicator.backgroundColor = UIColor.black
        indicator.color=UIColor.white
        indicator.center=self.center
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        return indicator;
    }
}
