//
//  PlaybackService.swift
//  Player
//
//  Created by michael on 2017-06-21.
//  Copyright © 2017 maz. All rights reserved.
//

import Foundation
import AVFoundation

protocol PlaybackDisplayDelegate : class {
//    var trackCount : Int? { get }
//    var currentIndex : Int? { get }
    
    func setTitle(title : String)
    func setCurrentTime(time : TimeInterval, duration : TimeInterval)
    func playbackReady()
    func playbackFailed()
    func playbackComplete()
    func playbackRepeat(shouldRepeat: Bool)
    func muteVolume(shouldMute: Bool)
}

protocol PlaybackModeDelegate : class {
    func playbackPlaying()
    func playbackPaused()
    func playbackDisposed()
}

private var playerItemStatusContext = 0

class PlaybackService : NSObject {
    static var playbackService :  PlaybackService?

    var media : [MediaChapter]?
    var mediaIndex : Int?
    
    var playbackRepeat : Bool = false
    var muteVolume : Bool = false
    
//    var assets : [AVAsset]?
//    var currentIndex = Int(-1)
    var currentAsset : AVAsset?
    var currentPlayerItem : AVPlayerItem?

    var assets : [AVAsset]?
    var playerItems : [AVPlayerItem]?

    var player : AVPlayer?
    var isPlaying : Bool?
    var avoidRestartOnLoad : Bool?

    weak var playbackDisplayDelegate : PlaybackDisplayDelegate?
    weak var playbackModeDelegate : PlaybackModeDelegate?
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    var timeObserverToken : Any?
    var itemEndObserver : Any?
    var lastPlaybackRate : Float?

    let statusKeypath : String = "status"
    let refreshInterval : Double = 0.5

    var videoPlaybackStartDate : TimeInterval?
    var videoPlaybackEndDate : TimeInterval?

//    init(url: URL) {
//        self.asset = AVAsset(url: url)
//        super.init()
//        self.prepareToPlay()
//    }

    class func sharedInstance() -> PlaybackService {

        DispatchQueue.once(token: "com.kjvrvg.dispatch.playback") {
            playbackService = PlaybackService()
            playbackService?.isPlaying = false
            
            // avoidRestartOnLoad always false on first playback
            playbackService?.avoidRestartOnLoad = false
        }
        return playbackService!
    }

    deinit {
        if self.itemEndObserver != nil {
            NotificationCenter.default.removeObserver(self.itemEndObserver, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            self.itemEndObserver = nil
        }
        self.currentPlayerItem?.removeObserver(self, forKeyPath: statusKeypath)
        self.currentPlayerItem = nil
        self.player = nil
        self.currentAsset = nil

        self.assets = nil
        self.playerItems = nil

        isPlaying = false
        videoPlaybackEndDate = Date().timeIntervalSinceNow

    }

    func disposePlayback() {
        self.playbackModeDelegate?.playbackDisposed()
        
        if self.timeObserverToken != nil {
            print("enter")
            self.player?.removeTimeObserver(self.timeObserverToken)
            self.timeObserverToken = nil
            print("exit")
        }

        if self.itemEndObserver != nil {
            NotificationCenter.default.removeObserver(self.itemEndObserver, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            self.itemEndObserver = nil
        }
        
        self.currentPlayerItem?.removeObserver(self, forKeyPath: statusKeypath)
        self.currentPlayerItem = nil
        self.player = nil
        self.currentAsset = nil

        self.assets = nil
        self.playerItems = nil

        isPlaying = false
        videoPlaybackEndDate = Date().timeIntervalSinceNow
    }

    func prepareToPlayUrls(urls : [URL], playIndex : Int) -> Void {
        
        if avoidRestartOnLoad! == false  {
            let assets : [AVAsset] = urls.map { AVAsset(url:$0) }
            let keys : Array = ["tracks", "duration", "commonMetadata", "availableMediaCharacteristicsWithMediaSelectionOptions"]
            
            let playerItems : [AVPlayerItem] = assets.map { AVPlayerItem(asset: $0, automaticallyLoadedAssetKeys: keys) }
            
            self.assets = assets
            self.playerItems = playerItems
            
            if let playAsset = self.assets?[playIndex] {
                self.currentAsset = playAsset
                self.currentPlayerItem = self.playerItems?[playIndex]
                //         playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
                
                self.currentPlayerItem?.addObserver(self, forKeyPath: statusKeypath, options: NSKeyValueObservingOptions(rawValue: 0), context: &playerItemStatusContext)
                self.player = AVPlayer.init(playerItem: self.currentPlayerItem)
                
            }
        } else {
            // avoidRestartOnLoad should be one-shot
            avoidRestartOnLoad = false
        }
        

    }

    func stopObserving(playerItem : AVPlayerItem) {
        if self.timeObserverToken != nil {
            print("enter")
            self.player?.removeTimeObserver(self.timeObserverToken)
            self.timeObserverToken = nil
            print("exit")
        }
        
        if self.itemEndObserver != nil {
            NotificationCenter.default.removeObserver(self.itemEndObserver, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            self.itemEndObserver = nil
        }
        
        playerItem.removeObserver(self, forKeyPath: statusKeypath)
    }
    
    
    func startObservingAndReplace(playerItem : AVPlayerItem) {
        if let currentPlayerItem : AVPlayerItem = self.currentPlayerItem {
            if playerItem == currentPlayerItem {
                currentPlayerItem.addObserver(self, forKeyPath: statusKeypath, options: NSKeyValueObservingOptions(rawValue: 0), context: &playerItemStatusContext)
                self.player?.replaceCurrentItem(with: currentPlayerItem)
            }
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("observeValue")

        guard context == &playerItemStatusContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if context == &playerItemStatusContext {
            if self.currentPlayerItem?.status == .readyToPlay {
                print(".readyToPlay")
                addPlayerItemTimeObserver()
                addItemEndObserverForPlayerItem(item : self.currentPlayerItem!)

                // whenever we load a new track we should
                // reset the playback position to kCMTimeZero
                DispatchQueue.main.async { [unowned self] in self.player?.seek(to: kCMTimeZero) }

                self.playbackDisplayDelegate?.setCurrentTime(time: CMTimeGetSeconds(kCMTimeZero), duration: CMTimeGetSeconds((self.currentPlayerItem?.duration)!))

                self.playbackDisplayDelegate?.setTitle(title: self.contentTitle(mediaIndex: self.mediaIndex!))
                self.playbackDisplayDelegate?.playbackReady()
                
                // do not repeat track by default
                self.playbackDisplayDelegate?.playbackRepeat(shouldRepeat: playbackRepeat)
                
                // do not mute by default
                self.playbackDisplayDelegate?.muteVolume(shouldMute: muteVolume)

            }
            else if self.currentPlayerItem?.status == .failed  {
                print("failed!")
                self.playbackDisplayDelegate?.playbackFailed()
                disposePlayback()
            }

        } else {
            print("failed to load audio!")
        }
        
    }

    func addPlayerItemTimeObserver() {
        let interval : CMTime = CMTimeMakeWithSeconds(refreshInterval, Int32(NSEC_PER_SEC))

        timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [unowned self] time in
            let currentTime : TimeInterval = CMTimeGetSeconds(time)
            let duration : TimeInterval = CMTimeGetSeconds((self.currentPlayerItem?.duration)!)
            self.playbackDisplayDelegate?.setCurrentTime(time: currentTime, duration: duration)
            self.playbackDisplayDelegate?.setTitle(title: self.contentTitle(mediaIndex: self.mediaIndex!))
        })
    }

    func addItemEndObserverForPlayerItem(item : AVPlayerItem) {
        //        itemEndObserver = NSNotification.defaultCenter().addOb
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main
        
        self.itemEndObserver = center.addObserver(self, selector: #selector(PlaybackService.playerItemDidReachEnd(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        
    }

    func playerItemDidReachEnd(note : NSNotification) {
        print("playerItemDidReachEnd note: \(note)")
        
        if playbackRepeat == true {
            DispatchQueue.main.async { [unowned self] in
                self.player?.seek(to: kCMTimeZero)
                self.playbackDisplayDelegate?.playbackReady()
            }
        } else {
            if let item : AVPlayerItem = note.object as? AVPlayerItem {
                
                if let nextItem : AVPlayerItem = self.nextPlayerItem(currentItem: item) {
                    if let nextIndex : Int = (self.playerItems?.index(of: nextItem)) {
                        
                        // stop observing the current item
                        // and play next item
                        self.playbackToNextItem(currentItem: item, nextIndex: nextIndex, nextItem: nextItem)
                    }
                } else {
                    // could not advance to next item
                    // assume we are at end of playerItem array
                    DispatchQueue.main.async {
                        [unowned self] in
                        self.player?.seek(to: kCMTimeZero,
                                          completionHandler: { (Bool) in
                                            self.playbackDisplayDelegate?.playbackComplete()
                        })
                        
                    }
                }
                
            }
        }
    }
    
    func nextPlayerItem(currentItem : AVPlayerItem) -> AVPlayerItem? {
        if let currentIndex : Int = (self.playerItems?.index(of: currentItem)) {
            
            if currentIndex >= 0 && currentIndex == (self.playerItems?.count)! - 1 {
                return nil
            }
            // not at end
            if let nextItem : AVPlayerItem = (self.playerItems?[currentIndex + 1]) {
                return nextItem
            }

        }
        return nil
    }
    
    func previousPlayerItem(currentItem : AVPlayerItem) -> AVPlayerItem? {
        if let currentIndex : Int = (self.playerItems?.index(of: currentItem)) {
            
            if currentIndex == 0 {
                // we are at the first item already
                // cannot obtain previous item
                return nil
            }
            // not at first item
            if let previousItem : AVPlayerItem = (self.playerItems?[currentIndex - 1]) {
                return previousItem
            }
            
        }
        return nil
    }
    
    func playbackToNextItem(currentItem : AVPlayerItem, nextIndex : Int, nextItem : AVPlayerItem) {
        
        stopObserving(playerItem: currentItem)
        
        print("nextItem: \(nextItem) nextIndex: \(nextIndex)")
        self.currentAsset = self.assets?[nextIndex]
        self.currentPlayerItem = self.playerItems?[nextIndex]
        
        self.mediaIndex? = nextIndex
        
        if let currentPlayerItem : AVPlayerItem = self.currentPlayerItem {
            startObservingAndReplace(playerItem: currentPlayerItem)
        }
    }

    func playbackToPreviousItem(currentItem : AVPlayerItem, previousIndex : Int, previousItem : AVPlayerItem) {
        
        stopObserving(playerItem: currentItem)
        
        print("previousItem: \(previousItem) previousIndex: \(previousIndex)")
        self.currentAsset = self.assets?[previousIndex]
        self.currentPlayerItem = self.playerItems?[previousIndex]
        
        self.mediaIndex? = previousIndex
        
        if let currentPlayerItem : AVPlayerItem = self.currentPlayerItem {
            startObservingAndReplace(playerItem: currentPlayerItem)
        }
    }
    
    private func contentTitle(mediaIndex index: (Int)) -> String {
        
        var finalString : String = ""
        
        if let localizedName = self.media?[self.mediaIndex!].localizedName {
            finalString = finalString.appending("\(localizedName)\n ")
        }
        
        if let presenterName = self.media?[self.mediaIndex!].presenterName {
            finalString = finalString.appending("\(presenterName) • ")
        }
        
        if let sourceMaterial = self.media?[self.mediaIndex!].sourceMaterial {
            finalString = finalString.appending(sourceMaterial)
        }
        return finalString
    }

}

extension PlaybackService : PlaybackTransportDelegate {

    func stop() {
//        isPlaying = Double((self.player?.rate)!) > 0.0 ? true : false
        print("PlaybackTransportDelegate stop")
        self.player?.rate = 0.0
        self.playbackDisplayDelegate?.playbackComplete()
        isPlaying = false
    }

    func pause() {
        print("PlaybackTransportDelegate pause")
        self.lastPlaybackRate = self.player?.rate;
        self.player?.pause()
        self.playbackModeDelegate?.playbackPaused()
        isPlaying = false
//        self.player?.removeTimeObserver(self.timeObserverToken)
    }

    func play() {
        print("PlaybackTransportDelegate play")
        videoPlaybackEndDate = Date().timeIntervalSinceNow
//        self.addPlayerItemTimeObserver()
        self.player?.play()
        self.playbackModeDelegate?.playbackPlaying()
        isPlaying = Double((self.player?.rate)!) > 0.0 ? true : false
    }

    func jumpedToTime(time: TimeInterval) {
        print("PlaybackTransportDelegate jumpedToTime: \(String(time))")
        self.player?.seek(to: CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC)))
        //        self.player?.seek(to: CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        isPlaying = false
    }

    func scrubbingDidStart() {
        print("PlaybackTransportDelegate scrubbingDidStart")
        self.lastPlaybackRate = self.player?.rate;
        self.player?.pause()
        self.player?.removeTimeObserver(self.timeObserverToken)
        isPlaying = false
    }

    func scrubbedToTime(time: TimeInterval) {
        print("PlaybackTransportDelegate scrubbedToTime: \(String(time))")
        self.currentPlayerItem?.cancelPendingSeeks()
        self.player?.seek(to: CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        isPlaying = false
    }

    func scrubbingDidEnd() {
        print("PlaybackTransportDelegate scrubbingDidEnd")
        self.addPlayerItemTimeObserver()
        if Double(self.lastPlaybackRate!) > 0.0 {
            self.player?.play()
            isPlaying = true
        }
    }
    
    func nextTrack() {
        if let currentPlayerItem : AVPlayerItem = self.currentPlayerItem {
            if let nextItem : AVPlayerItem = self.nextPlayerItem(currentItem: currentPlayerItem) {
                if let nextIndex : Int = (self.playerItems?.index(of: nextItem)) {
                    // stop observing the current item
                    // play next item

                    self.playbackToNextItem(currentItem: currentPlayerItem, nextIndex: nextIndex, nextItem: nextItem)
                }

            }
        }
        
    }
    
    func previousTrack() {
        if let currentPlayerItem : AVPlayerItem = self.currentPlayerItem {
            if let previousItem : AVPlayerItem = self.previousPlayerItem(currentItem: currentPlayerItem) {
                if let previousIndex : Int = (self.playerItems?.index(of: previousItem)) {
                    // stop observing the current item
                    // play next item
                    self.playbackToPreviousItem(currentItem: currentPlayerItem, previousIndex : previousIndex, previousItem : previousItem)
                }
                
            }
        }
    }
    
    func playbackRepeat(shouldRepeat : Bool) {
        self.playbackRepeat = shouldRepeat
    }

    func toggleVolume(shouldMute : Bool) {
        self.muteVolume = shouldMute
        
        if muteVolume == true {
            self.player?.volume = Float(0)
        } else {
            self.player?.volume = Float(1)
        }
    }

}

extension AVAsset {
    func title() -> String? {
        let status : AVKeyValueStatus = self.statusOfValue(forKey: "commonMetadata", error: nil)
        if status == .loaded {
            let items = AVMetadataItem.metadataItems(from: self.commonMetadata, withKey: AVMetadataCommonKeyTitle, keySpace: AVMetadataKeySpaceCommon)

            if items.count > 0 {
                let titleItem : AVMetadataItem = items.first!
                return titleItem.value as? String
            }
        }
        return nil
    }
}


