//
//  PlayerViewController.swift
//  Player
//
//  Created by michael on 2017-06-15.
//  Copyright © 2017 maz. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

protocol PlaybackTransportDelegate: class {
    func play()
    func pause()
    func stop()
    func scrubbingDidStart()
    func scrubbedToTime(time : TimeInterval)
    func scrubbingDidEnd()
    func jumpedToTime(time : TimeInterval)
    func nextTrack()
    func previousTrack()
    func playbackRepeat(shouldRepeat : Bool)
    func toggleVolume(shouldMute : Bool)
    func playerViewDidAppear()
    func playerViewDidDisappear()
}

class PlayerViewController : BaseClass {

    @IBOutlet weak var playPauseButton : UIButton!
    @IBOutlet weak var previousButton : UIButton!
    @IBOutlet weak var nextButton : UIButton!
    @IBOutlet weak var scrubberSlider : UISlider!
    @IBOutlet weak var currentTimeLabel : UILabel!
    @IBOutlet weak var remainingTimeLabel : UILabel!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet weak var contentTitleLabel: UILabel!
    
    weak var playbackTransportDelegate : PlaybackTransportDelegate?
    var scrubbing : Bool?
    var playingWhileScrubbing : Bool?
    var playerIsPlaying : Bool = false
    var sessionIsResuming : Bool = false
    var playbackRepeat : Bool?
    var muteVolume : Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PlayerViewController viewDidLoad")

        scrubberSlider.value = Float(0)
        scrubberSlider.addTarget(self, action: #selector(PlayerViewController.scrubberChanged) , for: .valueChanged)
        scrubberSlider.addTarget(self, action: #selector(PlayerViewController.scrubberTouchUpInside), for: .touchUpInside)
        scrubberSlider.addTarget(self, action: #selector(PlayerViewController.scrubberTouchDown), for: .touchDown)

        scrubbing = false
        playingWhileScrubbing = false

        emptyUIState()
        
            let mediaIndex = PlaybackService.sharedInstance().mediaIndex!

            if let media : [MediaChapter] = PlaybackService.sharedInstance().media {
                if let urls : [URL] = media.map({ URL(string: $0.url!)! }) {
                    
                    // only show spinner if playback service is not currently playing
                    if (PlaybackService.sharedInstance().player == nil) {
                        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loadingNotification.mode = MBProgressHUDMode.indeterminate
                    }

                    PlaybackService.sharedInstance().prepareToPlayUrls(urls: urls, playIndex: mediaIndex)
                    //            self.playerController?.playbackDisplayDelegate = self
                }
            }

        if PlaybackService.sharedInstance().isPlaying! {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "player_play_180"), for: .normal)
        } else {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
        }

        self.playbackTransportDelegate = PlaybackService.sharedInstance()
        PlaybackService.sharedInstance().playbackDisplayDelegate = self

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let transportDelegate = self.playbackTransportDelegate {
            transportDelegate.playerViewDidDisappear()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let transportDelegate = self.playbackTransportDelegate {
            transportDelegate.playerViewDidAppear()
        }
    }

    func emptyUIState() {
        currentTimeLabel.text = "--:--"
        remainingTimeLabel.text = "--:--"
        self.playPauseButton.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
//        self.repeatButton.setImage(#imageLiteral(resourceName: "repeat"), for: .normal)
    }
    
    func scrubberChanged() {
        print("scrubberChanged")
//        currentTimeLabel.text = "--:--"
//        remainingTimeLabel.text = "--:--"
        let time : Double = Double(scrubberSlider.value)
        if !time.isNaN {
            self.playbackTransportDelegate?.scrubbedToTime(time: Double(scrubberSlider.value))
        }
    }


    func scrubberTouchUpInside() {
        print("scrubberTouchUpInside")
        scrubbing = false;
        self.playbackTransportDelegate?.scrubbingDidEnd()

        let time : Double = Double(scrubberSlider.value)
        if !time.isNaN {
            self.playbackTransportDelegate?.scrubbedToTime(time: Double(scrubberSlider.value))
        }
        
        if let wasPlaying = playingWhileScrubbing {
            if wasPlaying {
                self.playbackTransportDelegate?.play()
            }
        }
    }


    func scrubberTouchDown() {
        print("scrubberTouchDown")
        
        if Double((PlaybackService.sharedInstance().player?.rate)!) > 0.0 {
            playingWhileScrubbing = true
        } else {
            playingWhileScrubbing = false
        }

        self.playbackTransportDelegate?.pause()
        scrubbing = true;
        self.playbackTransportDelegate?.scrubbingDidStart()
    }


    @IBAction func playPause(_ sender: Any) {
        print("PlayerViewController playPause")
        
        if Double((PlaybackService.sharedInstance().player?.rate)!) > 0.0 {
            playerIsPlaying = true
        }

        if let button = sender as? UIButton {
            if playerIsPlaying && !sessionIsResuming {
                self.playPauseButton.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
                self.playbackTransportDelegate?.pause()
                playerIsPlaying = false
                sessionIsResuming = false
            } else {
                self.playPauseButton.setImage(#imageLiteral(resourceName: "player_play_180"), for: .normal)
                self.playbackTransportDelegate?.play()
                playerIsPlaying = true
                sessionIsResuming = false
            }
        }
        
    }

    @IBAction func repeatTrack(_ sender: Any) {
        if let repeatTrack = self.playbackRepeat {
            self.playbackRepeat = !repeatTrack
            
            
            if let button = sender as? UIButton {
                if self.playbackRepeat == true {
                    button.setImage(#imageLiteral(resourceName: "repeat-2"), for: .normal)
                } else {
                    button.setImage(#imageLiteral(resourceName: "repeat"), for: .normal)
                }
                self.playbackTransportDelegate?.playbackRepeat(shouldRepeat: self.playbackRepeat!)
            }
        }
    }
    
    @IBAction func changeVolume(_ sender: Any) {
        if let muteVolume = self.muteVolume {
            self.muteVolume = !muteVolume
            
            if let button = sender as? UIButton {
                if self.muteVolume == true {
                    button.setImage(#imageLiteral(resourceName: "speaker-2"), for: .normal)
                } else {
                    button.setImage(#imageLiteral(resourceName: "speaker"), for: .normal)
                }
                self.playbackTransportDelegate?.toggleVolume(shouldMute: self.muteVolume!)
            }
        }
    }
    
    func setCurrentTime(time : TimeInterval, duration : TimeInterval) {
        if !time.isNaN && !duration.isNaN {

            print("setCurrentTime: \(time)")
            let currentSeconds = Int(ceil(time))
            let remainingTime = Int(duration - time)
            
            currentTimeLabel?.text = formatSeconds(value: currentSeconds)
            remainingTimeLabel?.text = formatSeconds(value: remainingTime)
            scrubberSlider.minimumValue = Float(0.0)
            scrubberSlider.maximumValue = Float(duration)
            scrubberSlider.value = Float(time)
        }
//            print("PlaybackDisplayDelegate setCurrentTime: \(String(time)) duration: \(String(duration))")
    }

    func formatSeconds(value: Int) -> String {
        let seconds = value % 60
        let minutes = value / 60

        let secondsText = timeText(from: seconds)
        let minutesText = timeText(from: minutes)

        return String("\(minutesText):\(secondsText)")
    }

    private func timeText(from number: Int) -> String {
        return number < 10 ? "0\(number)" : "\(number)"
    }

    @IBAction func previous(_ sender: Any) {
        print("previous")
        
        if let currentIndex = PlaybackService.sharedInstance().mediaIndex {
            if currentIndex != 0 {
                // we pause here because calling
                // previousTrack() alone will eventually
                // call playPause() and toggle play -> pause
                // ceasing playback

                self.playbackTransportDelegate?.pause()
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                
                self.playbackTransportDelegate?.previousTrack()
                
            }
        }

    }

    @IBAction func next(_ sender: Any) {
        print("next")
        
        if let currentIndex = PlaybackService.sharedInstance().mediaIndex {
            if currentIndex + 1 <= (PlaybackService.sharedInstance().media?.count)! - 1 {
                // we pause here because calling
                // nextTrack() alone will eventually
                // call playPause() and toggle play -> pause
                // ceasing playback
                
                self.playbackTransportDelegate?.pause()
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                
                self.playbackTransportDelegate?.nextTrack()
                
            }
        }
        
    }
}

extension PlayerViewController : PlaybackDisplayDelegate {

    func setTitle(title : String) {
//        print("PlaybackDisplayDelegate setTitle: \(title)")
        self.contentTitleLabel.text = title
    }

    func playbackReady() {
        MBProgressHUD.hide(for: self.view, animated: true)
        playerIsPlaying = false
        print("PlaybackDisplayDelegate playbackReady")
        playPause(self.playPauseButton)
    }

    func playbackFailed() {
        MBProgressHUD.hide(for: self.view, animated: true)
        self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem getting the media.", comment: ""))

        // "There was a problem getting the media." = "There was a problem getting the media.";
        print("PlaybackDisplayDelegate playbackFailed")
        emptyUIState()
//        playPause(self.playPauseButton)
    }

    func playbackComplete() {
        scrubberSlider.value = Float(0)
        emptyUIState()
        playerIsPlaying = false
        print("PlaybackDisplayDelegate playbackComplete")
    }
    
    func playbackRepeat(shouldRepeat: Bool) {
        playbackRepeat = shouldRepeat
        if playbackRepeat == false {
            self.repeatButton.setImage(#imageLiteral(resourceName: "repeat"), for: .normal)
        } else {
            self.repeatButton.setImage(#imageLiteral(resourceName: "repeat-2"), for: .normal)
        }
    }
    
    func muteVolume(shouldMute: Bool) {
        muteVolume = shouldMute
        if muteVolume == false {
            self.volumeButton.setImage(#imageLiteral(resourceName: "speaker"), for: .normal)
        } else {
            self.volumeButton.setImage(#imageLiteral(resourceName: "speaker-2"), for: .normal)
        }
    }
    
    func audioSessionInterrupted() {
        print("audioSessionInterrupted")

        self.playPauseButton.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
    }

    func audioSessionResumed() {
        print("audioSessionResumed")
        self.sessionIsResuming = true
        if self.playerIsPlaying {
            playPause(self.playPauseButton)
        }
//            }
    }
    
    func audioSessionRouteChange() {
        print("audioSessionRouteChange")
    }
    
}
