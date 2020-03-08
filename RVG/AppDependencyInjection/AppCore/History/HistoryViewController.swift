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
    
    var playbackHistoryViewController: PlaybackHistoryViewController!
    var downloadHistoryViewController: DownloadHistoryViewController!

    private var filterController: UISearchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        historySelectionControl.setTitle(NSLocalizedString("Playback", comment: "").l10n(), forSegmentAt: 0)
        historySelectionControl.setTitle(NSLocalizedString("Download", comment: "").l10n(), forSegmentAt: 1)

        self.embed(playbackHistoryViewController, in: self.listingContainer)
        
        
        filterController.dimsBackgroundDuringPresentation = false
        filterController.searchBar.placeholder = NSLocalizedString("Filter", comment: "").l10n()
        filterController.searchResultsUpdater = playbackHistoryViewController
        filterController.searchBar.delegate = playbackHistoryViewController // Monitor when the search button is tapped.
        filterController.searchBar.autocapitalizationType = .none
        //        searchController.dimsBackgroundDuringPresentation = true // The default is true.
        filterController.delegate = playbackHistoryViewController
        
        filterController.searchBar.enablesReturnKeyAutomatically = true
        filterController.searchBar.returnKeyType = .done
        
        navigationItem.searchController = filterController
        navigationItem.hidesSearchBarWhenScrolling = false

        
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
