//
//  MediaDetailViewController.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-31.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import XLActionController
import MagazineLayout


class MediaDetailsViewController: UIViewController, UICollectionViewDataSource /* , UICollectionViewDelegate */ {

    private struct Constants {
        static let mediaSection = 1
    }

    internal lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        //        collectionView.register(UINib(nibName: "SearchResultsCell", bundle: nil), forCellWithReuseIdentifier: SearchResultsCell.description())
        collectionView.register(UINib(nibName: "MediaItemCell", bundle: nil), forCellWithReuseIdentifier: MediaItemCell.description())
        collectionView.register(UINib(nibName: "MediaItemDetailsCell", bundle: nil), forCellWithReuseIdentifier: MediaItemDetailsCell.description())

        collectionView.isPrefetchingEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        return collectionView
    }()
    
    
    internal var viewModel: MediaDetailsViewModel!
    internal var downloadListingViewModel: DownloadListingViewModel!

    // MARK: Fields
    
    internal var viewModelSections: [MediaDetailsSectionViewModel] = []
//    internal var downloadingItems: [String: FileDownload] = [:]
//    internal var downloadedItems: [String: FileDownload] = [:]
    internal var selectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var previousSelectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var playbackState = Field<AssetPlaybackManager.playbackState>(.initial)

    private var lastProgressChangedUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()
    private var lastDownloadCompleteUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()

    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])

        let notificationCenter = NotificationCenter.default
        
        // MediaItemCell
//        notificationCenter.addObserver(self, selector: #selector(MediaDetailsViewController.handleUserDidTapMoreNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(MediaDetailsViewController.handleUserDidTapCancelNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
        
        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapRetryNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            DDLogDebug("notification: \(notification)")
            if let mediaItem: MediaItem = notification.object as? MediaItem,
                let weakSelf = self {
                // clear-out from interrupted items
                weakSelf.downloadListingViewModel.downloadInterruptedItems[mediaItem.uuid] = nil
                weakSelf.downloadListingViewModel.fetchDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
            }
        }
        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            DDLogDebug("notification: \(notification)")
            if let mediaItem: MediaItem = notification.object as? MediaItem,
                let weakSelf = self {
                weakSelf.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
            }
        }

        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            
                DDLogDebug("notification: \(notification)")
                /*
                 - some : Faithful_Word.MediaItem(contentProviderLink: nil, duration: 0.0, hashId: "gqRj", insertedAt: 1565925286.0, ipfsLink: nil, languageId: "en", largeThumbnailPath: nil, localizedname: "Matthew 1", medThumbnailPath: nil, mediaCategory: "bible", medium: "audio", ordinal: Optional(1), path: Optional("bible/en/0040-0001-Matthew-en.mp3"), playlistUuid: "8e06e658-9cdf-4ca0-8aa5-a3e958e6b035", presentedAt: nil, presenterName: Optional("Eli Lambert"), publishedAt: nil, smallThumbnailPath: nil, sourceMaterial: Optional("King James Bible (KJV)"), tags: [], trackNumber: Optional(1), updatedAt: Optional(1565925318.0), uuid: "39be7a9d-fbe8-49a3-a5d4-16c3e10b0c2d")
                 */
                if let mediaItem: MediaItem = notification.object as? MediaItem,
                    let weakSelf = self,
                    let path: String = mediaItem.path,
                    let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) {
                    let actionController = YoutubeActionController()
                    
                    
                    let fileIdentifier: String = mediaItem.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
                    //        actionController.addAction(Action(ActionData(title: "Add to Watch Later", image: UIImage(named: "yt-add-to-watch-later-icon")!), style: .default, handler: { action in
                    //        }))
                    
                    if let fileDownload: FileDownload = weakSelf.downloadListingViewModel.downloadedItems[mediaItem.uuid] {
                        actionController.addAction(Action(ActionData(title: "Delete File...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                            weakSelf.downloadListingViewModel.deleteFileDownload(for: mediaItem.uuid, pathExtension: remoteUrl.pathExtension)
                        }))
                    }  else if let downloading: FileDownload = weakSelf.downloadListingViewModel.downloadInterruptedItems[mediaItem.uuid] {
                        actionController.addAction(Action(ActionData(title: "Restart Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                            
                            // clear-out from interrupted items
                            weakSelf.downloadListingViewModel.downloadInterruptedItems[mediaItem.uuid] = nil
                            
                            weakSelf.downloadListingViewModel.fetchDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
                        })) } else if let downloading: FileDownload = weakSelf.downloadListingViewModel.downloadingItems[mediaItem.uuid] {
                        actionController.addAction(Action(ActionData(title: "Cancel Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                            weakSelf.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
                        }))
                    }
                    else {
                        actionController.addAction(Action(ActionData(title: "Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                            //                self.downloadListingService. fetchDownload(url: remoteUrl.absoluteString, filename: fileIdentifier, playableUuid: mediaItem.uuid)
                            weakSelf.downloadListingViewModel.fetchDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
                            
                        }))
                    }
                    if let fileDownload: FileDownload = weakSelf.downloadListingViewModel.downloadedItems[mediaItem.uuid] {
                        actionController.addAction(Action(ActionData(title: "Share File...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                            
                            weakSelf.shareFile(mediaItem: mediaItem)
                        }))
                    }
                    actionController.addAction(Action(ActionData(title: "Share Link...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                        weakSelf.shareLink(mediaItem: mediaItem)
                    }))
                    
                    actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "yt-cancel-icon")!), style: .cancel, handler: nil))
                    
                    weakSelf.present(actionController, animated: true, completion: nil)
                }
        }
    
        // Do any additional setup after loading the view.
        reactToViewModel()
        bindDownloadListingViewModel()

    }
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
    }

    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .observeOn(MainScheduler.instance)
            //            .filter{ $0[0].items.count > 0 }
            .next { [unowned self] sections in
                // first time loading sections
                //                if self.itemsUpdatedAtLeastOnce == false {
                self.viewModelSections = sections
                self.collectionView.reloadData()
            }.disposed(by: bag)
        
        // refresh the collection view every quarter second
        // so we can see things like download progress happen
        lastProgressChangedUpdate
            .observeOn(MainScheduler.instance)
            //            .distinctUntilChanged()
            .throttle(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe { [unowned self] indexPath in
                //                UIView.setAnimationsEnabled(false)
                if let path: IndexPath = indexPath.element {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadItemsAtIndexPaths([path], animationStyle: .none)
                    }
                }
                //                UIView.setAnimationsEnabled(true)
            }
            .disposed(by: bag)
        
        // refresh the collection view when a download completes
        // this should not be throttled to ensure
        // we capture the update
        lastDownloadCompleteUpdate
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] indexPath in
                //                UIView.setAnimationsEnabled(false)
                if let path: IndexPath = indexPath.element {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadItemsAtIndexPaths([path], animationStyle: .none)
                    }
                }
                //                UIView.setAnimationsEnabled(true)
            }
            .disposed(by: bag)
        

    }

    private func bindDownloadListingViewModel() {
        
        Observable.combineLatest(downloadListingViewModel.activeFileDownloads(viewModel.playable.playlist_uuid).asObservable(),
                                 downloadListingViewModel.storedFileDownloads(for: viewModel.playable.playlist_uuid).asObservable())
            .subscribe(onNext: { activeDownloads, fileDownloads in
                DDLogDebug("activeDownloads: \(activeDownloads) fileDownloads: \(fileDownloads)")
                
                // put activeDownloads in downloading
                activeDownloads.forEach({ [unowned self] fileDownload in
                    self.downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
                })
                
                // put .complete in downloaded
                var notCompleted: [FileDownload] = []
                // put anything that is not .complete in downloadingItems
                fileDownloads.forEach({ [unowned self] fileDownload in
                    if fileDownload.state != .complete {
                        notCompleted.append(fileDownload)
                    } else {
                        self.downloadListingViewModel.downloadedItems[fileDownload.playableUuid] = fileDownload
                        DDLogDebug("completedDownload: \(fileDownload)")
                    }
                })
                
                // put interrupted in downloaded, to allow the user the option of restarting
                // by tapping the restart button
                var interruptedDownloads: [FileDownload] = []
                notCompleted.forEach({ [unowned self] notCompletedDownload in
                    //                print("notCompletedDownload \(activeDownloads.contains { $0.playableUuid == notCompletedDownload.playableUuid })")
                    
                    let notCompletePresentInActive: Bool = activeDownloads.contains { $0.playableUuid == notCompletedDownload.playableUuid }
                    
                    if notCompletePresentInActive == false {
                        // interrupted
                        interruptedDownloads.append(notCompletedDownload)
                    }
                    
                    //                let interruptedDownloads: [FileDownload] = notCompleted.filter({ notCompletedDownload -> Bool in
                    //                    activeDownloads.contains(where: { activeDownload -> Bool in
                    //                        activeDownload.playlistUuid != notCompletedDownload.playlistUuid
                    //                    })
                })
                
                interruptedDownloads.forEach({ [unowned self] fileDownload in
                    self.downloadListingViewModel.downloadInterruptedItems[fileDownload.playableUuid] = fileDownload
                })
                
                DDLogDebug("interruptedDownloads: \(interruptedDownloads)")
                
            }).disposed(by: bag)

        // the moment the viewmodel playlistuuid changes we
        // get the file downloads for that playlist
        downloadListingViewModel.storedFileDownloads(for: viewModel.playable.playlist_uuid)
            .asObservable()
            .subscribe(onNext: { fileDownloads in
                
                fileDownloads.forEach({ [unowned self] fileDownload in
                    self.downloadListingViewModel.downloadedItems[fileDownload.playableUuid] = fileDownload
                })
                
                DDLogDebug("viewModel.playlistUuid: \(self.viewModel.playable.playlist_uuid) fileDownloads: \(fileDownloads)")
            })
            .disposed(by: bag)
        
        // refresh the collection view when a download gets deleted
        // this should not be throttled to ensure
        // we capture the update
        downloadListingViewModel.fileDownloadDeleted
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] playableUuid in
                
                if let playableUuid: String? = playableUuid.element,
                    let uuid: String = playableUuid,
                    let download: FileDownload = self.downloadListingViewModel.downloadedItems[uuid],
                    let indexPath: IndexPath = self.indexOfFileDownloadInViewModel(fileDownload: download) {
                    
                    // remove it from downloadedItems
                    self.downloadListingViewModel.downloadedItems[uuid] = nil
                    
                    if indexPath.row >= 0 {
                        UIView.performWithoutAnimation {
                            self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                        }
                    }
                }
            }
            .disposed(by: bag)
        
        downloadListingViewModel.fileDownloadDirty
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] fileDownload in
                let indexPath: IndexPath = self.indexOfFileDownloadInViewModel(fileDownload: fileDownload)
                if indexPath.row != -1 {
                    self.lastProgressChangedUpdate.onNext(indexPath)
                }

            }).disposed(by: bag)
        
        
        downloadListingViewModel.fileDownloadDirtyComplete
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] fileDownload in
                let indexPath: IndexPath = self.indexOfFileDownloadInViewModel(fileDownload: fileDownload)
                if indexPath.row != -1 {
                    self.lastDownloadCompleteUpdate.onNext(indexPath)
                }
                
            }).disposed(by: bag)

    }
    
    // returns -1 on not found
    private func indexOfFileDownloadInViewModel(fileDownload: FileDownload) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        var index: Int = -1
        var indexPath: IndexPath = IndexPath(row: index, section: Constants.mediaSection)
        
        // assume section 0
        
        if viewModelSections.count > 0 {
            let items: [MediaDetailsItemType] = viewModelSections[Constants.mediaSection].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            return item.uuid == fileDownload.playableUuid
                        }
                    case .details(_, _, _):
                        return false
                    }
                    
                }) ?? -1
            }
        }
        
        indexPath = IndexPath(row: index, section: Constants.mediaSection)
        return indexPath
    }
    
    // returns -1 on not found
    private func indexOfPlayableInViewModel(playable: Playable) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        var index: Int = -1
        var indexPath: IndexPath = IndexPath(row: index, section: Constants.mediaSection)
        
        // assume section 0
        
        if viewModelSections.count > 0 {
            let items: [MediaDetailsItemType] = viewModelSections[Constants.mediaSection].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            return item.uuid == playable.uuid
                        }
                    case .details(_,_,_):
                        return false
                    }
                    
                }) ?? -1
            }
        }
        indexPath = IndexPath(row: index, section: Constants.mediaSection)
        return indexPath
    }

    //    handleUserDidTapCancelNotification
    
    @objc func handleUserDidTapCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let mediaItem: MediaItem = notification.object as? MediaItem {
            self.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
        }
        
        
    }
    
}



// MARK: UICollectionViewDelegateMagazineLayout

extension MediaDetailsViewController: UICollectionViewDelegateMagazineLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
        return MagazineLayoutItemSizeMode(widthMode: .fullWidth(respectsHorizontalInsets: true), heightMode: .dynamic)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForHeaderInSectionAtIndex index: Int) -> MagazineLayoutHeaderVisibilityMode {
        return MagazineLayout.Default.HeaderVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForFooterInSectionAtIndex index: Int) -> MagazineLayoutFooterVisibilityMode {
        return MagazineLayout.Default.FooterVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForBackgroundInSectionAtIndex index: Int) -> MagazineLayoutBackgroundVisibilityMode {
        return MagazineLayout.Default.BackgroundVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalSpacingForItemsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}


extension MediaDetailsViewController: UICollectionViewDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModelSections.count
    }
    

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModelSections.count == 0 {
            return 0
        }
        return viewModelSections[section].items.count
    }
    
    //    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    //        let item: MediaListingItemType = viewModelSections[indexPath.section].items[indexPath.row]
    //
    //        switch item {
    //        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
    //            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
    //            switch enumPlayable {
    //
    //            case .playable(let item):
    //                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
    //
    //                if let _: FileDownload = downloadedItems[item.uuid] {
    //
    //                    drillInCell.playStateImageView.stopAnimating()
    //                    drillInCell.playStateImageView.layer.removeAllAnimations()
    //                }
    //            }
    //        }
    //    }
    //
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
        //        if viewModelSections[0].items.count > 0 {
        //        DDLogDebug("viewModelSections[indexPath.section].items[indexPath.row]: \(viewModelSections[indexPath.section].items[indexPath.row])")
        //        }
        let item: MediaDetailsItemType = viewModelSections[indexPath.section].items[indexPath.row]
        
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            switch enumPlayable {
                
            case .playable(let item):
                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showIcon: false)
                
                // show play icon or animating wave icon
                if let selectedPlayable: Playable = selectedPlayable.value {
                    if item.uuid == selectedPlayable.uuid {
                        
                        // show the animation unless the AssetPlaybackManager is not actually playing
                        if playbackState.value != .playing {
                            drillInCell.playStateImageView.stopAnimating()
                            drillInCell.playStateImageView.layer.removeAllAnimations()
                            if let playImage: UIImage = UIImage(named: "play") {
                                drillInCell.playStateImageView.image = playImage
                            }
                        } else {
                            if let waveImageFrame1: UIImage = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame1),
                                let waveImageFrame2: UIImage = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame2),
                                let waveImageFrame3: UIImage = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame3),
                                let waveImageFrame4: UIImage = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame4),
                                let waveImageFrame5: UIImage = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame5)
                            {
                                let animations: [UIImage] = [waveImageFrame1, waveImageFrame2, waveImageFrame3, waveImageFrame4, waveImageFrame5]
                                drillInCell.playStateImageView.animationImages = animations
                                drillInCell.playStateImageView.animationDuration = 1.0
                                drillInCell.playStateImageView.startAnimating()
                                
                                drillInCell.playStateImageView.image = UIImage(named: AnimationImageTitleConstants.waveAnimationFrame1)
                            }
                        }
                        
                    } else {
                        drillInCell.playStateImageView.stopAnimating()
                        drillInCell.playStateImageView.layer.removeAllAnimations()
                        if let playImage: UIImage = UIImage(named: "play") {
                            drillInCell.playStateImageView.image = playImage
                        }
                    }
                }
                
                // update UI with downloading items
                
                if let fileDownload: FileDownload = downloadListingViewModel.downloadingItems[item.uuid] {
                    
                    drillInCell.progressView.isHidden = false
                    drillInCell.amountDownloaded.isHidden = false
                    drillInCell.amountDownloaded.text = ""
                    drillInCell.downloadStateButton.isHidden = false
                    drillInCell.downloadStateButton.isEnabled = true
                    
                    switch fileDownload.state {
                    case .initial:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        drillInCell.downloadStateButton.isHidden = true
                        drillInCell.downloadStateButton.setTitle("", for: .normal)
                        
                    case .initiating:
                        drillInCell.progressView.isHidden = false
                        drillInCell.progressView.progress = fileDownload.progress
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = ""
                    case .inProgress:
                        drillInCell.progressView.isHidden = false
                        drillInCell.progressView.progress = fileDownload.progress
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.cancelFile), for: .normal)
                    case .cancelling:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        // don't hide cancel button quite yet
                        drillInCell.downloadStateButton.isHidden = false
                        // disable cancel button while cancelling
                        drillInCell.downloadStateButton.isEnabled = false
                        
                    case .cancelled:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(contentsOfFile: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadListingViewModel.downloadingItems[item.uuid] = nil
                        
                    case .complete:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadListingViewModel.downloadingItems[item.uuid] = nil
                    case .interrupted:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(contentsOfFile: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadListingViewModel.downloadingItems[item.uuid] = nil
                    case .error:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(contentsOfFile: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadListingViewModel.downloadingItems[item.uuid] = nil
                        
                    case .unknown:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        drillInCell.downloadStateButton.isHidden = true
                        drillInCell.downloadStateButton.setImage(UIImage(contentsOfFile: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                    }
                } else {
                    drillInCell.progressView.isHidden = true
                    drillInCell.amountDownloaded.isHidden = true
                    drillInCell.amountDownloaded.text = ""
                }
                
                // update UI with downloaded items
                
                if let fileDownload: FileDownload = downloadListingViewModel.downloadedItems[item.uuid] {
                    drillInCell.progressView.isHidden = true
                    drillInCell.amountDownloaded.isHidden = false
                    
                    if fileDownload.progress == 1.0 {
                        drillInCell.amountDownloaded.text = fileDownload.completedCount.fileSizeString() //fileSizeFormattedString(for: fileDownload.completedCount)
                        
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                    }
                        //                    else if fileDownload.progress < 1.0 && fileDownload.progress >= 0.0 {
                        //                        drillInCell.amountDownloaded.text = String(describing: " \(fileSizeFormattedString(for: fileDownload.completedCount)) / \(fileSizeFormattedString(for: fileDownload.totalCount))")
                        //
                        //                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        //                        drillInCell.downloadStateButton.isHidden = false
                        //                        drillInCell.downloadStateButton.isEnabled = true
                        //                    }
                    else if fileDownload.completedCount > fileDownload.totalCount {
                        drillInCell.amountDownloaded.text = NSLocalizedString("Download Error", comment: "").l10n()
                        
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.errorDeletedFile), for: .normal)
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                    }
                    //                    drillInCell.amountDownloaded.text = (fileDownload.progress == 1.0) ? fileSizeFormattedString(for: fileDownload.completedCount) :
                    //                    drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                } else {
                    // if we just deleted the file, update the UI
                    
                    // make sure that it is not in the downloading items
                    if let _: FileDownload = downloadListingViewModel.downloadingItems[item.uuid] {
                        // do nothing because we want to show progress in UI
                        // if it is downloading
                    } else {
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        //                        drillInCell.downloadStateButton.isHidden = true
                        drillInCell.downloadStateButton.setImage(nil, for: .normal)
                        
                    }
                }
                
                if let fileDownload: FileDownload = downloadListingViewModel.downloadInterruptedItems[item.uuid] {
                    drillInCell.progressView.isHidden = true
                    drillInCell.amountDownloaded.isHidden = false
                    
                    if fileDownload.progress < 1.0 && fileDownload.progress >= 0.0 {
                        drillInCell.amountDownloaded.text = String(describing: " \(fileDownload.completedCount.fileSizeString() ) / \(fileDownload.totalCount.fileSizeString())")
                        
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = true
                    } else if fileDownload.completedCount > fileDownload.totalCount {
                        drillInCell.amountDownloaded.text = NSLocalizedString("Download Error", comment: "").l10n()
                        
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.errorDeletedFile), for: .normal)
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                    }
                    //                    drillInCell.amountDownloaded.text = (fileDownload.progress == 1.0) ? fileSizeFormattedString(for: fileDownload.completedCount) :
                    //                    drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                }

            }
            return drillInCell
            
        case .details(let playable, let presentedAt, let showBottomSeparator):
            
//            switch enumPlayable {
//            case .playable(let item):
                let detailCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemDetailsCell.description(), for: indexPath) as! MediaItemDetailsCell
                
                detailCell.set(playable: playable, title: playable.localizedname, presenter: playable.presenter_name ?? NSLocalizedString("Unknown Presenter", comment: "").l10n(), showBottomSeparator: showBottomSeparator, showTitle: false)
                return detailCell
//            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
    
    
}

//extension MediaDetailsViewController {
//    func shareLink(mediaItem: MediaItem) {
//        if let hashLink: URL = URL(string: "https://api.faithfulword.app/m"),
//            let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
//            let shareUrl: URL = hashLink.appendingPathComponent(mediaItem.hashId) {
//            DDLogDebug("hashLink: \(shareUrl)")
//
//            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
//            let itemsToShare: [Any] = [message, shareUrl]
//
//            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
//            
//            activityViewController.excludedActivityTypes = [
//                .addToReadingList,
//                .openInIBooks,
//                .print,
//                .saveToCameraRoll,
//                .postToWeibo,
//                .postToFlickr,
//                .postToVimeo,
//                .postToTencentWeibo]
//
//            self.present(activityViewController, animated: true, completion: {})
//        }
//
//
//    }
//
//    func shareFile(mediaItem: MediaItem) {
//        // copy file to temp dir to rename it
//        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
//        // generate temp file url path
//
//        if let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
//            let path: String = mediaItem.path,
//            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) {
//
//            let firstPart: String = "\(presenterName.replacingOccurrences(of: " ", with: ""))"
//            let secondPart: String = "\(mediaItem.localizedname.replacingOccurrences(of: " ", with: "")).\(remoteUrl.pathExtension)"
//            let destinationLastPathComponent: String = String(describing: "\(firstPart)-\(secondPart)")
//
//            let sourceFileUrl: URL = FileSystem.savedDirectory.appendingPathComponent(mediaItem.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)")))
//            let temporaryFileURL: URL = temporaryDirectoryURL.appendingPathComponent(destinationLastPathComponent)
//            DDLogDebug("temporaryFileURL: \(temporaryFileURL)")
//
//            // capture the audio file as a Data blob and then write it
//            // to temp dir
//
//            do {
//                let audioData: Data = try Data(contentsOf: sourceFileUrl, options: .uncached)
//                try audioData.write(to: temporaryFileURL, options: .atomicWrite)
//            } catch {
//                DDLogDebug("error writing temp audio file: \(error)")
//                return
//            }
//
//            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
//            let itemsToShare: [Any] = [message, temporaryFileURL]
//
//            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
//
//            activityViewController.excludedActivityTypes = [
//                .addToReadingList,
//                .openInIBooks,
//                .print,
//                .saveToCameraRoll,
//                .postToWeibo,
//                .postToFlickr,
//                .postToVimeo,
//                .postToTencentWeibo]
//
//            self.present(activityViewController, animated: true, completion: {})
//        }
//
//
//    }
//}
