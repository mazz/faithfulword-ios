//
//  DemoMusicPlayerController.swift
//  LNPopupControllerExample
//
//  Created by Leo Natan on 8/8/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

import UIKit
import LNPopupController
import AVFoundation

class DemoMusicPlayerController: UIViewController {

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    @IBOutlet weak var albumArtImageView: UIImageView!

    let accessibilityDateComponentsFormatter = DateComponentsFormatter()

    var playPauseButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!

    var assets = [Asset]()
    var timer : Timer?

    // MARK: Fields

    public var viewModel: DemoMusicPlayerViewModel!
    public var remoteCommandService: RemoteCommandService!
    public var assetPlaybackService: AssetPlaybackService!
//    var assetPlaybackManager: AssetPlaybackManager! {
//        didSet {
//            // Add the Key-Value Observers needed to keep the UI up to date.
//            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress), options: NSKeyValueObservingOptions.new, context: nil)
//            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration), options: NSKeyValueObservingOptions.new, context: nil)
//            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition), options: NSKeyValueObservingOptions.new, context: nil)
//
//            // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
//            let notificationCenter = NotificationCenter.default
//
//            notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
//            notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
//            notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
//            notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
//        }
//    }

//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animateAlongsideTransition(in: self.popupPresentationContainer?.view, animation: { context in
//            self._setPopupItemButtons(traitCollection: newCollection)
//        }, completion: nil)
//    }
//
//    private func _setPopupItemButtons(traitCollection: UITraitCollection) {
//        let pause = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: self, action: #selector(DemoMusicPlayerController.doPlayPause))
//        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
//        let next = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: self, action: #selector(DemoMusicPlayerController.nextFwd))
//        next.accessibilityLabel = NSLocalizedString("Next Track", comment: "")
//
////        if UserDefaults.standard.object(forKey: PopupSettings.BarStyle) as? LNPopupBarStyle == LNPopupBarStyle.compact {
////            popupItem.leftBarButtonItems = [ pause ]
////            popupItem.rightBarButtonItems = [ next ]
////        }
////        else {
//            popupItem.rightBarButtonItems = [ pause, next ]
////        }
////        popupBar.marqueeScrollEnabled = true
//    }

    var songTitle: String = "" {
        didSet {
            if isViewLoaded {
                songNameLabel.text = songTitle
            }

            popupItem.title = songTitle
        }
    }
    var albumTitle: String = "" {
        didSet {
            if isViewLoaded {
                albumNameLabel.text = albumTitle
            }
//            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion <= 9 {
                popupItem.subtitle = albumTitle
//            }
        }
    }
    var albumArt: UIImage = UIImage() {
        didSet {
            if isViewLoaded {
                albumArtImageView.image = albumArt
            }
            popupItem.image = albumArt
            popupItem.accessibilityImageLabel = NSLocalizedString("Album Art", comment: "")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        playPauseButton = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: self, action: #selector(DemoMusicPlayerController.doPlayPause))
        playPauseButton.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        nextButton = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: self, action: #selector(DemoMusicPlayerController.doNextTrack))
        nextButton.accessibilityLabel = NSLocalizedString("Next Track", comment: "")

        popupItem.rightBarButtonItems = [ playPauseButton, nextButton ]

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        songNameLabel.text = songTitle
        albumNameLabel.text = albumTitle
        albumArtImageView.image = albumArt

        popupItem.title = songTitle
        popupItem.subtitle = albumTitle

//        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(DemoMusicPlayerController._timerTicked(_:)), userInfo: nil, repeats: true)

        remoteCommandService.activatePlaybackCommands(true)

        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
//        let notificationCenter = NotificationCenter.default
//
//        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)


        assets = [Asset(assetName: "Psalm2-DD", urlAsset: AVURLAsset(url: URL(string: "https://d2v5mbm9qwqitj.cloudfront.net/bible/en/0019-0002-Psalms-en.mp3")!))]
    }

//    deinit {
//        // Remove all notification observers.
//        let notificationCenter = NotificationCenter.default
//
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
//    }

//    deinit {
//        // Remove all KVO and notification observers.
//        let notificationCenter = NotificationCenter.default
//
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
//
//        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress))
//        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration))
//        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition))
//    }

    // MARK: Key-Value Observing Method

//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == #keyPath(AssetPlaybackManager.percentProgress) {
//            print("#keyPath AssetPlaybackManager.duration: \(assetPlaybackManager.percentProgress)")
//            progressView.progress = assetPlaybackManager.percentProgress
//        }
//        else if keyPath == #keyPath(AssetPlaybackManager.duration) {
//            print("#keyPath AssetPlaybackManager.duration: \(assetPlaybackManager.duration)")
////            guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.duration)) else { return }
//
////            totalPlaybackDurationTextField.stringValue = stringValue
//        }
//        else if keyPath == #keyPath(AssetPlaybackManager.playbackPosition) {
//            print("#keyPath AssetPlaybackManager.playbackPosition: \(assetPlaybackManager.playbackPosition)")
////            guard let stringValue = accessibilityDateComponentsFormatter.string(from: TimeInterval(assetPlaybackManager.playbackPosition)) else { return }
//
////            currentPlaybackPositionTextField.stringValue = stringValue
////            popupItem.accessibilityProgressValue = "\(accessibilityDateComponentsFormatter.string(from: Double(popupItem.progress) * Double(assetPlaybackManager.duration))!) \(NSLocalizedString("of", comment: "")) \(accessibilityDateComponentsFormatter.string(from: Double(assetPlaybackManager.duration))!)"
//        }
//        else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
//    }

    // MARK: Notification Handler Methods

//    @objc func handleCurrentAssetDidChangeNotification(notification: Notification) {
//        if assetPlaybackManager.asset != nil {
//            print("assetPlaybackManager.asset.assetName: \(assetPlaybackManager.asset.assetName)")
////            print("assetPlaybackManager.asset.assetName: \(assetPlaybackManager.asset.assetName)")
////            print("assetPlaybackManager.asset.assetName: \(assetPlaybackManager.asset.assetName)")
////            print("assetPlaybackManager.asset.assetName: \(assetPlaybackManager.asset.assetName)")
////            assetNameTextField.stringValue = assetPlaybackManager.asset.assetName
//
//            guard let asset = assetPlaybackManager.asset else {
//                return
//            }
//
//            let urlAsset = asset.urlAsset
//
//            let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()
//
//            let image = UIImage(data: artworkData) ?? UIImage()
//
//            albumArtImageView.image = image
//
//
//
////            for i in assets.startIndex..<assets.endIndex {
////                if asset.assetName == assets[i].assetName {
////                    assetListTableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
////                    break
////                }
////            }
//        }
//        else {
//            albumArtImageView.image = nil
////            assetNameTextField.stringValue = "Select Item Below to play"
////            totalPlaybackDurationTextField.stringValue = "-:--"
////            currentPlaybackPositionTextField.stringValue = "-:--"
////            playbackProgressIndicator.doubleValue = 0.0
////            assetListTableView.deselectAll(nil)
//        }
//
////        updateToolbarItemState()
//    }

//    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
//        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
//        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
//
//        if assetIndex < assets.count - 1 {
//            assetPlaybackManager.asset = assets[assetIndex + 1]
//        }
//    }
//
//    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
//        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
//        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
//
//        if assetIndex > 0 {
//            assetPlaybackManager.asset = assets[assetIndex - 1]
//        }
//    }
//
//    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
//        updateToolbarItemState()
//    }

    @objc func _timerTicked(_ timer: Timer) {
        popupItem.progress += 0.0002;
        popupItem.accessibilityProgressLabel = NSLocalizedString("Playback Progress", comment: "")



        let totalTime = TimeInterval(250)
        popupItem.accessibilityProgressValue = "\(accessibilityDateComponentsFormatter.string(from: TimeInterval(popupItem.progress) * totalTime)!) \(NSLocalizedString("of", comment: "")) \(accessibilityDateComponentsFormatter.string(from: totalTime)!)"

        progressView.progress = popupItem.progress

        if popupItem.progress >= 1.0 {
            timer.invalidate()
            popupPresentationContainer?.dismissPopupBar(animated: true, completion: nil)
        }
    }

    @objc func doPlayPause() {
        assetPlaybackService.asset = assets[0]
//    assetPlaybackManager.asset = Asset(assetName: "Psalm2-DD", urlAsset: AVURLAsset(url: URL(string: "https://d2v5mbm9qwqitj.cloudfront.net/bible/en/0019-0002-Psalms-en.mp3")!))
        assetPlaybackService.togglePlayPause()
//        print("doPlayPause assetPlaybackManager.asset: \(assetPlaybackManager.asset)")

    }

    @objc func doNextTrack() {

    }

    @objc func updateToolbarItemState() {
        print("updateToolbarItemState")
//        if assetPlaybackManager.asset == nil {
//            backwardButton.isEnabled = false
//            playPauseButton.isEnabled = false
//            forwardButton.isEnabled = false
//
//            playPauseButton.image = #imageLiteral(resourceName: "Play")
//        }
//        else {
//            backwardButton.isEnabled = true
//            playPauseButton.isEnabled = true
//            forwardButton.isEnabled = true
//
//            if assetPlaybackManager.player.rate == 0 {
//                playPauseButton.image = #imageLiteral(resourceName: "Play")
//            }
//            else {
//                playPauseButton.image = #imageLiteral(resourceName: "Pause")
//            }
//        }
    }

}

