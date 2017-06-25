//
//  ViewController.swift
//  Player
//
//  Created by michael on 2017-06-13.
//  Copyright © 2017 maz. All rights reserved.
//

import UIKit

class PlayerContainerViewController: UIViewController {

    @IBOutlet var barRightButton: UIButton!
    @IBOutlet var barLeftButton: UIButton!

    private let playerViewControllerIndex = 0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func back(_ sender: AnyObject) {
        print("back")
        self.dismiss(animated: true) { _ in }
    }

    @IBAction func close(_ sender: AnyObject) {
        print("close")
        self.dismiss(animated: true) { _ in }
        PlaybackService.sharedInstance().disposePlayback()
    }
}

