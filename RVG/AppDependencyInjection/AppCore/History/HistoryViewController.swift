//
//  HistoryViewController.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-08.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {

    
    @IBOutlet weak var listingContainer: UIView!
    @IBOutlet weak var historySelectionControl: UISegmentedControl!
//    var historyPlaybackViewModel: MediaFilterViewModel!
//    var historyDownloadViewModel: MediaFilterViewModel!
    
    var playbackHistoryViewController: MediaHistoryViewController!
    var downloadHistoryViewController: MediaHistoryViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        historySelectionControl.setTitle(NSLocalizedString("Playback", comment: "").l10n(), forSegmentAt: 0)
        historySelectionControl.setTitle(NSLocalizedString("Download", comment: "").l10n(), forSegmentAt: 1)

        self.embed(playbackHistoryViewController, in: self.listingContainer)
    }

    @IBAction func tappedSegmentedControl(_ sender: Any) {
        if let control: UISegmentedControl = sender as? UISegmentedControl {
            if control.selectedSegmentIndex == 0 {
                self.remove(downloadHistoryViewController)
                self.embed(playbackHistoryViewController, in: self.listingContainer)
            } else if control.selectedSegmentIndex == 1 {
                self.remove(playbackHistoryViewController)
                self.embed(downloadHistoryViewController, in: self.listingContainer)
            }
        }
    }
}
