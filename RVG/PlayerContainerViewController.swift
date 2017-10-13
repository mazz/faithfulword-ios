//
//  ViewController.swift
//  Player
//
//  Created by michael on 2017-06-13.
//  Copyright © 2017 maz. All rights reserved.
//

import UIKit
import L10n_swift

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
        self.dismiss(animated: true) {   }
    }

    @IBAction func close(_ sender: AnyObject) {
        print("close")
        
        self.showTwoButtonAlertWithLeftAction(title: NSLocalizedString("Do you want to close the player?", comment: "").l10n(),
                                              buttonTitleLeft: NSLocalizedString("Yes", comment: "").l10n(),
                                              buttonTitleRight: NSLocalizedString("No", comment: "").l10n()) {
                                                
                                                self.dismiss(animated: true) { }
                                                PlaybackService.sharedInstance().disposePlayback()
        }
        
    }
}

