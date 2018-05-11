import Foundation

import RxSwift
import AVFoundation
import MediaPlayer

public protocol RemoteCommandServicing {

    //    var player: AVPlayer { get }
    //
    //    func play()
    //    var asset: Asset { get }

    //    // Current authentication state
    //    var authState: Observable<AuthStatus> { get }
    //    // Current user
    //    var currentUser: ApplicationUser? { get }
    //    // Current user's music service accounts
    //    //    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }
    //
    //    func start()
    //    func logout()
    //
    //    func startLoginFlow() -> Single<Void>
    //    //    func startLoginFlow(over viewController: UIViewController) -> Single<Void>
    //    //    func startRegistrationFlow(over viewController: UIViewController) -> Single<Void>
    //    //    func startUpdateFlow(over viewController: UIViewController)
    //
    //    //    func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]>
}

/// Manages all account related things
public final class RemoteCommandService: NSObject {

    // MARK: Fields
//    private let bag = DisposeBag()
    // Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()

    // MARK: Dependencies

    //    private var loginSequencer: LoginSequencing
    private let assetPlaybackService: AssetPlaybackService
    //
    public init(assetPlaybackService: AssetPlaybackService
        ) {
        self.assetPlaybackService = assetPlaybackService
    }
/*
    deinit {
        activatePlaybackCommands(false)
//        toggleNextTrackCommand(false)
//        togglePreviousTrackCommand(false)
//        toggleSkipForwardCommand(false)
//        toggleSkipBackwardCommand(false)
//        toggleSeekForwardCommand(false)
//        toggleSeekBackwardCommand(false)
//        toggleChangePlaybackPositionCommand(false)
//        toggleLikeCommand(false)
//        toggleDislikeCommand(false)
//        toggleBookmarkCommand(false)
    }
*/
    /*
    func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(RemoteCommandService.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(RemoteCommandService.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(RemoteCommandService.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(RemoteCommandService.handleTogglePlayPauseCommandEvent(_:)))

        }
        else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(RemoteCommandService.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(RemoteCommandService.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(RemoteCommandService.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(RemoteCommandService.handleTogglePlayPauseCommandEvent(_:)))
        }

        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
    }
*/

//
//    func toggleNextTrackCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandService.handleNextTrackCommandEvent(_:)))
//        }
//        else {
//            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(RemoteCommandService.handleNextTrackCommandEvent(_:)))
//        }
//
//        remoteCommandCenter.nextTrackCommand.isEnabled = enable
//    }
//

    /*
    func togglePreviousTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandService.handlePreviousTrackCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(RemoteCommandService.handlePreviousTrackCommandEvent(event:)))
        }

        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }


 */
//
//    func toggleSkipForwardCommand(_ enable: Bool, interval: Int = 0) {
//        if enable {
//            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
//            remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(RemoteCommandService.handleSkipForwardCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.skipForwardCommand.removeTarget(self, action: #selector(RemoteCommandService.handleSkipForwardCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.skipForwardCommand.isEnabled = enable
//    }
//
//    func toggleSkipBackwardCommand(_ enable: Bool, interval: Int = 0) {
//        if enable {
//            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
//            remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(RemoteCommandService.handleSkipBackwardCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.skipBackwardCommand.removeTarget(self, action: #selector(RemoteCommandService.handleSkipBackwardCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.skipBackwardCommand.isEnabled = enable
//    }
//
//    func toggleSeekForwardCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(RemoteCommandService.handleSeekForwardCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(RemoteCommandService.handleSeekForwardCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.seekForwardCommand.isEnabled = enable
//    }
//
//    func toggleSeekBackwardCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(RemoteCommandService.handleSeekBackwardCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(RemoteCommandService.handleSeekBackwardCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.seekBackwardCommand.isEnabled = enable
//    }
//
//    func toggleChangePlaybackPositionCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(RemoteCommandService.handleChangePlaybackPositionCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self, action: #selector(RemoteCommandService.handleChangePlaybackPositionCommandEvent(event:)))
//        }
//
//
//        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = enable
//    }
//
//    func toggleLikeCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.likeCommand.addTarget(self, action: #selector(RemoteCommandService.handleLikeCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.likeCommand.removeTarget(self, action: #selector(RemoteCommandService.handleLikeCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.likeCommand.isEnabled = enable
//    }
//
//    func toggleDislikeCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.dislikeCommand.addTarget(self, action: #selector(RemoteCommandService.handleDislikeCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.dislikeCommand.removeTarget(self, action: #selector(RemoteCommandService.handleDislikeCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.dislikeCommand.isEnabled = enable
//    }
//
//    func toggleBookmarkCommand(_ enable: Bool) {
//        if enable {
//            remoteCommandCenter.bookmarkCommand.addTarget(self, action: #selector(RemoteCommandService.handleBookmarkCommandEvent(event:)))
//        }
//        else {
//            remoteCommandCenter.bookmarkCommand.removeTarget(self, action: #selector(RemoteCommandService.handleBookmarkCommandEvent(event:)))
//        }
//
//        remoteCommandCenter.bookmarkCommand.isEnabled = enable
//    }

//    // MARK: MPRemoteCommand handler methods.
//
//    // MARK: Playback Command Handlers

    /*
    @objc func handlePauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackService.pause()

        return .success
    }

    @objc func handlePlayCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackService.play()

        return .success
    }

    @objc func handleStopCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackService.stop()

        return .success
    }

    @objc func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackService.togglePlayPause()

        return .success
    }

*/

//    // MARK: Track Changing Command Handlers
//    @objc func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
//        if assetPlaybackService.asset != nil {
//            assetPlaybackService.nextTrack()
//
//            return .success
//        }
//        else {
//            return .noSuchContent
//        }
//    }
//
    /*
    @objc func handlePreviousTrackCommandEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if assetPlaybackService.asset != nil {
            assetPlaybackService.previousTrack()

            return .success
        }
        else {
            return .noSuchContent
        }
    }

 */
//
//    // MARK: Skip Interval Command Handlers
//    @objc func handleSkipForwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
//        assetPlaybackService.skipForward(event.interval)
//
//        return .success
//    }
//
//    @objc func handleSkipBackwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
//        assetPlaybackService.skipBackward(event.interval)
//
//        return .success
//    }
//
//    // MARK: Seek Command Handlers
//    @objc func handleSeekForwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
//
//        switch event.type {
//        case .beginSeeking: assetPlaybackService.beginFastForward()
//        case .endSeeking: assetPlaybackService.endRewindFastForward()
//        }
//        return .success
//    }
//
//    @objc func handleSeekBackwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
//        switch event.type {
//        case .beginSeeking: assetPlaybackService.beginRewind()
//        case .endSeeking: assetPlaybackService.endRewindFastForward()
//        }
//        return .success
//    }
//
//    @objc func handleChangePlaybackPositionCommandEvent(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
//        assetPlaybackService.seekTo(event.positionTime)
//
//        return .success
//    }
//
//    // MARK: Feedback Command Handlers
//    @objc func handleLikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
//
//        if assetPlaybackService.asset != nil {
//            print("Did recieve likeCommand for \(assetPlaybackService.asset.assetName)")
//            return .success
//        }
//        else {
//            return .noSuchContent
//        }
//    }
//
//    @objc func handleDislikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
//
//        if assetPlaybackService.asset != nil {
//            print("Did recieve dislikeCommand for \(assetPlaybackService.asset.assetName)")
//            return .success
//        }
//        else {
//            return .noSuchContent
//        }
//    }
//
//    @objc func handleBookmarkCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
//
//        if assetPlaybackService.asset != nil {
//            print("Did recieve bookmarkCommand for \(assetPlaybackService.asset.assetName)")
//            return .success
//        }
//        else {
//            return .noSuchContent
//        }
//    }
}

extension RemoteCommandService: RemoteCommandServicing {
}
