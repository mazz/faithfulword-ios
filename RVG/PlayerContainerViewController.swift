//
//  ViewController.swift
//  Player
//
//  Created by michael on 2017-06-13.
//  Copyright © 2017 maz. All rights reserved.
//

import UIKit

class PlayerContainerViewController: BaseClass {

    @IBOutlet var barRightButton: UIButton!
    @IBOutlet var barLeftButton: UIButton!
    @IBOutlet weak var barTitleLabel: UILabel!
    
    private let playerViewControllerIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    }

    @IBAction func back(_ sender: AnyObject) {
        print("back")
        self.dismiss(animated: true) { _ in }
    }

    @IBAction func close(_ sender: AnyObject) {
        print("close")
        
        self.showTwoButtonAlertWithLeftAction(title: NSLocalizedString("Do you want to close the player?", comment: ""),
                                              buttonTitleLeft: NSLocalizedString("Yes", comment: ""),
                                              buttonTitleRight: NSLocalizedString("No", comment: "")) { (nil) in
                                                
                                                self.dismiss(animated: true) { _ in }
                                                PlaybackService.sharedInstance().disposePlayback()
        }
        
    }
}

