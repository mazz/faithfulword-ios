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
    var historyPlaybackViewModel: MediaFilterViewModel!
    var historyDownloadViewModel: MediaFilterViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        historySelectionControl.setTitle(NSLocalizedString("Playback", comment: "").l10n(), forSegmentAt: 0)
        historySelectionControl.setTitle(NSLocalizedString("Download", comment: "").l10n(), forSegmentAt: 1)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
