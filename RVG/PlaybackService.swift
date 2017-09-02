//
//  PlaybackService.swift
//  Player
//
//  Created by michael on 2017-06-21.
//  Copyright © 2017 maz. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

struct PausedState {
    let pausedTime: TimeInterval
    let duration: TimeInterval
    let displayedTitle: String
}

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
    func audioSessionInterrupted()
    func audioSessionResumed()
    func audioSessionRouteChange()
}

protocol PlaybackModeDelegate : class {
    func playbackPlaying()
    func playbackPaused()
    func playbackDisposed()
}

private var playerItemStatusContext = 0

class PlaybackService : NSObject {
    static var playbackService :  PlaybackService?

    var media : [Playable]?
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
    
    var pausedState: PausedState?
    
    /*  we need to watch visibility state of the playbackDisplayDelegate to workaround a problem where
     if the playerviewcontroller is not modal while the user interrupts the audio session, and it is playing
     playback will not resume on audio session resume (AVAudioSessionInterruptionTypeKey: 0) */
    var playerViewIsVisible : Bool = false
    
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

    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlaybackService.handleAudioSessionInterruption(note:)), name:.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(PlaybackService.handleAudioSessionRouteChange(note:)), name:.AVAudioSessionRouteChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlaybackService.handleMediaServicesReset), name:.AVAudioSessionMediaServicesWereReset, object: AVAudioSession.sharedInstance())
    }

    class func sharedInstance() -> PlaybackService {

        DispatchQueue.once(token: "com.kjvrvg.dispatch.playback") {
            playbackService = PlaybackService()
            playbackService?.isPlaying = false
            
            // avoidRestartOnLoad always false on first playback
            playbackService?.avoidRestartOnLoad = false
            playbackService?.pausedState = nil// PausedState(pausedTime: 0.0, displayedTitle: "")
            
            playbackService?.setupNowPlayingInfoCenter()
        }
        return playbackService!
    }

    deinit {
        if self.itemEndObserver != nil {
            NotificationCenter.default.removeObserver(self.itemEndObserver, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            self.itemEndObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionMediaServicesWereReset, object: AVAudioSession.sharedInstance())
        
        self.currentPlayerItem?.removeObserver(self, forKeyPath: statusKeypath)
        self.currentPlayerItem = nil
        self.player = nil
        self.currentAsset = nil

        self.assets = nil
        self.playerItems = nil

        isPlaying = false
        videoPlaybackEndDate = Date().timeIntervalSinceNow
        UIApplication.shared.endReceivingRemoteControlEvents()

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
        
        // initialize the audio session only once
        if self.player == nil {
            do {
                
                // to enable remote events, AVAudioSessionCategoryPlayback must be set
                // remote events fail with AVAudioSessionCategoryPlayAndRecord
                // AVAudioSessionCategoryPlayback and .allowBluetooth combination will always throw an exception
                // .allowBluetooth lower quality audio
                // .allowBluetoothA2DP sounds great however
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback,
                                                                with: [.allowBluetoothA2DP,
                                                                       .mixWithOthers,
                                                                       .defaultToSpeaker])

                
                //            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.allowBluetooth, .mixWithOthers, .defaultToSpeaker])
                
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch let error as NSError {
                print("setting (AVAudioSessionCategoryPlayAndRecord, with: [.allowBluetooth, .mixWithOthers, .defaultToSpeaker]) failed: \(error)")
                
            }
            
            UIApplication.shared.beginBackgroundTask {}
            

            //UIApplication.shared.beginReceivingRemoteControlEvents()
//            setupNowPlayingInfoCenter()
        }
        

        
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

    private func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.audioPlayer.resume()
            self.play()
            self.updateNowPlayingInfoCenter()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.audioPlayer.pause()
            self.pause()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.nextTrack()
            
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.previousTrack()
            return .success
        }
    }
    
    func stopObserving(playerItem : AVPlayerItem) {
        
        if let timeObserverToken = self.timeObserverToken {
//            if timeObserverToken != nil {
            print("enter")
            self.player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
            print("exit")
//            }
        }
        
        if let itemEndObserver = self.itemEndObserver {
//            if self.itemEndObserver != nil {
                NotificationCenter.default.removeObserver(itemEndObserver, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
                self.itemEndObserver = nil
//            }
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
            
            if let currentPlayerItem = self.currentPlayerItem {
                if currentPlayerItem.status == .readyToPlay {
                    print(".readyToPlay")
                    addPlayerItemTimeObserver()
                    addItemEndObserverForPlayerItem(item : self.currentPlayerItem!)
                    
                    // whenever we load a new track we should
                    // reset the playback position to kCMTimeZero
                    DispatchQueue.main.async { [unowned self] in self.player?.seek(to: kCMTimeZero) }
                    
                    if let playbackDisplayDelegate = self.playbackDisplayDelegate {
                        playbackDisplayDelegate.setCurrentTime(time: CMTimeGetSeconds(kCMTimeZero), duration: CMTimeGetSeconds(currentPlayerItem.duration))
                        
                        playbackDisplayDelegate.setTitle(title: self.contentTitle(mediaIndex: self.mediaIndex!))
                        playbackDisplayDelegate.playbackReady()
                        
                        // do not repeat track by default
                        playbackDisplayDelegate.playbackRepeat(shouldRepeat: playbackRepeat)
                        
                        // do not mute by default
                        playbackDisplayDelegate.muteVolume(shouldMute: muteVolume)
                        
//                        setupNowPlayingInfoCenter()
                    } else {
                        self.player?.play()
//                        setupNowPlayingInfoCenter()
                    }
                    
                    
                }
                else if currentPlayerItem.status == .failed  {
                    print("failed!")
                    self.playbackDisplayDelegate?.playbackFailed()
                    disposePlayback()
                }
            }
            

        } else {
            print("failed to load audio!")
        }
        
    }

    func addPlayerItemTimeObserver() {
        let interval : CMTime = CMTimeMakeWithSeconds(refreshInterval, Int32(NSEC_PER_SEC))

        timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [unowned self] time in
            if let displayDelegate = self.playbackDisplayDelegate {
                let currentTime : TimeInterval = CMTimeGetSeconds(time)
                let duration : TimeInterval = CMTimeGetSeconds((self.currentPlayerItem?.duration)!)
                displayDelegate.setCurrentTime(time: currentTime, duration: duration)
                displayDelegate.setTitle(title: self.contentTitle(mediaIndex: self.mediaIndex!))
                displayDelegate.playbackRepeat(shouldRepeat: self.playbackRepeat)
                displayDelegate.muteVolume(shouldMute: self.muteVolume)
                
                self.updateNowPlayingInfoCenter()
            }
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
        
        if let item : AVPlayerItem = note.object as? AVPlayerItem {
//            playbackForward(itemEnded: item)
            if item == self.currentPlayerItem {
                
                if playbackRepeat == true {
                    DispatchQueue.main.async { [unowned self] in
                        self.player?.seek(to: kCMTimeZero)
                        self.playbackDisplayDelegate?.playbackReady()
                    }
                } else {
                    if let nextItem : AVPlayerItem = self.nextPlayerItem(currentItem: item) {
                        if let nextIndex : Int = (self.playerItems?.index(of: nextItem)) {
                            
                            // stop observing the current item
                            // and play next item
                            // queueing on main dispatch queue seems to fix
                            // a race condition where the timeObserverToken
                            // would outlast self.player in the case where
                            // the user scrubs to the end of the track
                            // but scrubs back quickly
                            DispatchQueue.main.async { [unowned self] in
                                self.playbackToNextItem(currentItem: item, nextIndex: nextIndex, nextItem: nextItem)
                            }
                            
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
    }
    
//    func playbackForward(itemEnded: AVPlayerItem) {
//        if playbackRepeat == true {
//            DispatchQueue.main.async { [unowned self] in
//                self.player?.seek(to: kCMTimeZero)
//                self.playbackDisplayDelegate?.playbackReady()
//            }
//        } else {
//            if let nextItem : AVPlayerItem = self.nextPlayerItem(currentItem: itemEnded) {
//                if let nextIndex : Int = (self.playerItems?.index(of: nextItem)) {
//                    
//                    // stop observing the current item
//                    // and play next item
//                    // queueing on main dispatch queue seems to fix
//                    // a race condition where the timeObserverToken
//                    // would outlast self.player in the case where
//                    // the user scrubs to the end of the track
//                    // but scrubs back quickly
//                    DispatchQueue.main.async { [unowned self] in
//                        self.playbackToNextItem(currentItem: itemEnded, nextIndex: nextIndex, nextItem: nextItem)
//                    }
//                    
//                }
//            } else {
//                // could not advance to next item
//                // assume we are at end of playerItem array
//                DispatchQueue.main.async {
//                    [unowned self] in
//                    self.player?.seek(to: kCMTimeZero,
//                                      completionHandler: { (Bool) in
//                                        self.playbackDisplayDelegate?.playbackComplete()
//                    })
//                    
//                }
//            }
//        }
//    }

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
    
    func updateNowPlayingInfoCenter() {
        
        guard let currentItem = self.currentPlayerItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
            return
        }
        
        guard let media = self.media else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
            return
        }
        
        guard let mediaIndex: Int = self.mediaIndex else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
            return
        }
        
        guard let player = self.player  else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: AnyObject]()
            return
        }
//Double((self.player?.rate)!
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: media[mediaIndex].localizedName ?? "",
                               MPMediaItemPropertyArtist: media[mediaIndex].presenterName ?? "",
                               MPNowPlayingInfoPropertyElapsedPlaybackTime: CMTimeGetSeconds(player.currentTime()),
                               MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(currentItem.duration),
                               MPNowPlayingInfoPropertyPlaybackRate: Double(player.rate)]
    }
    
    private func contentTitle(mediaIndex index: (Int)) -> String {
        
        var finalString : String = ""
        
        if let localizedName = self.media?[self.mediaIndex!].localizedName {
            finalString = finalString.appending("\(localizedName)\n ")
        }
        
        if let presenterName = self.media?[self.mediaIndex!].presenterName {
            finalString = finalString.appending("\(presenterName)")
        }
        
        if let sourceMaterial = self.media?[self.mediaIndex!].sourceMaterial {
            if sourceMaterial != "" {
                finalString = finalString.appending(" • \(sourceMaterial)")
            }
        }
        return finalString
    }

    func handleAudioSessionInterruption(note : NSNotification) {
        print("handleAudioSessionInterruption note.userInfo: \(note.userInfo!)")

        var gotInterrupted : Bool = false
        var didResume : Bool = false
        
        if let interrupted : Int = note.userInfo?["AVAudioSessionInterruptionTypeKey"] as? Int {
            self.playbackDisplayDelegate?.audioSessionInterrupted()
            gotInterrupted = interrupted == 1
        }
        
        
        if let resumed : Int = note.userInfo?["AVAudioSessionInterruptionOptionKey"] as? Int {
            didResume = resumed == 1
            
            if !playerViewIsVisible && didResume {
                //                sessionInterruptedWhilePlayerViewNotVisible = true
                self.player?.play()
            }

            self.playbackDisplayDelegate?.audioSessionResumed()
        }
        
        print("gotInterrupted: \(gotInterrupted) didResume: \(didResume)")
        
        // playing: false gotInterrupted: true didResume: false -- interrupting
        // playing: false gotInterrupted: false didResume: true -- resuming

    }
    
    func handleAudioSessionRouteChange(note : NSNotification) {
        print("handleAudioSessionRouteChange note.userInfo: \(note.userInfo!)")
        var playing : Bool?
        
        if let player = self.player {
            playing = Double(player.rate) > 0.0 ? true : false
        }
        
        print("handleAudioSessionRouteChange playing: \(playing)")

        self.playbackDisplayDelegate?.audioSessionRouteChange()
        
    }
    
    func handleMediaServicesReset() {
        print("handleMediaServicesReset")
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
        if self.timeObserverToken != nil {
            self.player?.removeTimeObserver(self.timeObserverToken)
        }
        isPlaying = false
    }

    func scrubbedToTime(time: TimeInterval) {
        print("PlaybackTransportDelegate scrubbedToTime: \(String(time))")
        self.currentPlayerItem?.cancelPendingSeeks()
        self.player?.seek(to: CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        self.playbackDisplayDelegate?.setCurrentTime(time: time, duration: CMTimeGetSeconds((self.currentPlayerItem?.duration)!))
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

    func playerViewDidDisappear() {
        print("playerViewDidDisappear")
        self.playerViewIsVisible = false
        // reset this flag for later
//        self.sessionInterruptedWhilePlayerViewNotVisible = false
    }

    func playerViewDidAppear() {
        print("playerViewDidAppear")
        self.playerViewIsVisible = true
        // reset this flag for later
//        self.sessionInterruptedWhilePlayerViewNotVisible = false
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


