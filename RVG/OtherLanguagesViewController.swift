//
//  OtherLanguagesViewController.swift
//  RVG
//
//  Created by maz on 2017-06-01.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit

class OtherLanguagesViewController: UIViewController {

    @IBOutlet weak var toListenToLabel: UILabel!
    @IBOutlet weak var tutorialView: UIView!
    
    var looper: Looper?

    override func viewDidLoad() {
        super.viewDidLoad()

        looper?.start(in: tutorialView.layer)
        
//        self.navigationController?.isNavigationBarHidden=false
        self.title = NSLocalizedString("Other Languages", comment: "")
        self.toListenToLabel.text = NSLocalizedString("To listen to the Bible in other languages, follow the instructions in the video below.", comment: "")

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        looper?.stop()
    }
}
