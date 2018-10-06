import Foundation
import RxSwift
import RxCocoa
import LNPopupController
import AVFoundation

public final class MediaListingCoordinator {
    
    // MARK: Fields
    internal var playlistId: String?
    internal var mediaType: MediaType?
    internal var navigationController: UINavigationController?
    internal var mediaListingViewController: MediaListingViewController?

    private var mediaListingFlowCompletion: FlowCompletion!

    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>) {
        self.uiFactory = uiFactory
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
    }
}

// MARK: <NavigationCoordinating>
extension MediaListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        // 1. Hang on to the completion block for when the user if done with now-playing.
        mediaListingFlowCompletion = completion
        
        if let playlistId = playlistId, let mediaType = mediaType {
            self.mediaListingViewController = self.uiFactory.makeMediaListing(playlistId: playlistId, mediaType: mediaType)
            if let mediaListingViewController = self.mediaListingViewController {
                setup(mediaListingViewController)
                self.navigationController = mediaListingViewController.navigationController
                
                handle(eventsFrom: mediaListingViewController.viewModel)
            }
        }
    }

    private func swapInPlaybackFlow(for playable: Playable, playlist: [Playable]) {
        self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
            // do nothing because the bottom popup should appear
            // when the playbackViewController loads

            let popupController = playbackViewController as! PopupContentController

            if let localizedName = playable.localizedName,
                let presenterName = playable.presenterName,
                let thumbImage = UIImage(named: "Titus1-9") {
                popupController.songTitle = localizedName
                popupController.albumTitle = presenterName
                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                popupController.albumArt = thumbImage
                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "")

                // generate single playable
//                guard let localizedName = playable.localizedName,
//                    let path = playable.path,
//                    let url = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
//                    else {
//                        return
//                }
//
//                popupController.playbackAsset = Asset(assetName: localizedName,
//                                                      artist: presenterName,
//                                                      urlAsset: AVURLAsset(url: url))

                // generate playlist
//                var assets = [Asset]()
//
//                let enumerator = playlist.enumerated()
//                assets = enumerator.compactMap { playable in
//                    guard let localizedName = playable.1.localizedName,
//                        let presenterName = playable.1.presenterName,
//                        let path = playable.1.path,
//                        let url = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return nil }
//                        return Asset(assetName: localizedName,
//                                     artist: presenterName,
//                                     urlAsset: AVURLAsset(url: url))
//                }
                //                Asset(assetName: "Psalm2-DD", urlAsset: AVURLAsset(url: URL(string: "https://d2v5mbm9qwqitj.cloudfront.net/bible/en/0019-0002-Psalms-en.mp3")!))

//                popupController.playlistAssets = assets

                if let navigationController = self.navigationController {
                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
                    //                navigationController.popupItem.title = localizedName
                    //                navigationController.popupItem.subtitle = presenterName

                    //                print("navigationController.popupItem.title: \(navigationController.popupItem.title)")
                    //                print("navigationController.popupItem.subtitle: \(navigationController.popupItem.subtitle)")

                    //                navigationController.popupBar.barStyle = .compact
                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                    navigationController.popupBar.imageView.layer.cornerRadius = 5
                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
                }

//                self.resettablePlaybackCoordinator.value.updatePlaybackAsset(playable)
            }

        }, completion: { _ in
            self.navigationController!.dismiss(animated: true)
            self.resettablePlaybackCoordinator.reset()

        }, context: .other)
    }

    func goToPlayback(for playable: Playable) {
        print("goToPlayback playable: \(playable)")

        guard let _ = playable.localizedName,
            let _ = playable.presenterName
            else { return }

        //        self.resettablePlaybackCoordinator.value.playableItem = playable
        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!

//        var playables: [Playable] = []
        // hack? assume this playable comes from this controllers' viewmodel
//        if let viewController = mediaListingViewController {
////            let array = viewController.viewModel.sections.value[0].items
////            array.map { mediaListingItemType -> Void in
////                print("mediaListingItemType: \(mediaListingItemType)")
////                if case .drillIn(let type, _, _, _) = mediaListingItemType {
////                    switch type {
////                    case .playable(let item):
////                        print("item: \(item)")
////                        playables.append(item)
////                        //                        self?.assetPlaybackService.playableItem.value = item
////                    }
////                }
////                //                return result
////            }
//            print("playables: \(playables)")
//
//            //                let filteredArray = mediaListingItemType.filter {
//            //                    switch $0 {
//            //                    case let .WithString(value):
//            //                        return value == "C"
//            //                    default:
//            //                        return false
//            //                    }
//            //                }
//            //                mediaListingItemType.
//            //                mediaListingItemType.drillIn(type, _, _, _)//.drillIn(type, _, _, _).item()
//            //            }
//
//        }

        swapInPlaybackFlow(for: playable, playlist: (mediaListingViewController?.viewModel.media.value)!)

        //        let popupContentController = self.uiFactory.makePopupPlayer()
        //        popupContentController.songTitle = localizedName
        //        popupContentController.albumTitle = presenterName
        //        popupContentController.albumArt = UIImage(named: "titus1-9_thumb_lg")!//images[(indexPath as NSIndexPath).row]
        //        popupContentController.popupItem.accessibilityHint = NSLocalizedString("Double Tap to Expand the Mini Player", comment: "")
        //
        //        self.navigationController?.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
        //
        //        self.navigationController?.popupBar.barStyle = .compact
        //        self.navigationController?.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
        //        self.navigationController?.popupBar.imageView.layer.cornerRadius = 5
        //        self.navigationController?.presentPopupBar(withContentViewController: popupContentController, animated: true, completion: nil)

    }
}

// MARK: Event handling for medialisting screen
extension MediaListingCoordinator {
    private func handle(eventsFrom mediaListingViewModel: MediaListingViewModel) {
        print("handle(eventsFrom mediaListingViewModel")
        mediaListingViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .playable(let item):
                print(".defaultType: \(item)")
                self.goToPlayback(for: item)
            default:
                break
            }
            }.disposed(by: bag)
    }
}

