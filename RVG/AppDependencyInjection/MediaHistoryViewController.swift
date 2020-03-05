//
//  MediaHistoryViewController.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-24.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import XLActionController
import MagazineLayout
import os.log

/// Add service screen
public final class MediaHistoryViewController: UIViewController, UICollectionViewDataSource /*,  UICollectionViewDelegate */ {
    // MARK: Private
    
    private struct Constants {
        static let mediaSection = 0
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        //        collectionView.register(MediaItemCell.self, forCellWithReuseIdentifier: MediaItemCell.description())
        collectionView.register(UINib(nibName: "MediaItemCell", bundle: nil), forCellWithReuseIdentifier: MediaItemCell.description())
        
        collectionView.isPrefetchingEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        return collectionView
    }()
    
    var itemsUpdatedAtLeastOnce = false
    
    // MARK: Dependencies
    
    internal var viewModel: HistoryMediaViewModeling!
    //    internal var searchViewModel: MediaSearchViewModel!
    internal var playbackViewModel: PlaybackControlsViewModel!
    internal var downloadListingViewModel: DownloadListingViewModel!
    internal var mediaSearchResultsViewController: MediaSearchResultsViewController!
    
    // MARK: Fields
    
    internal var viewModelSections: [MediaListingSectionViewModel] = []
    //    internal var downloadingItems: [String: FileDownload] = [:]
    //    internal var downloadedItems: [String: FileDownload] = [:]
    internal var selectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var previousSelectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var playbackState = Field<AssetPlaybackManager.playbackState>(.initial)
    
    let noResultLabel: UILabel = UILabel(frame: .zero)
    
    
    /// MARK: Search
    
    internal var viewModelSearchSections: [MediaListingSectionViewModel] = []
    
    /// State restoration values.
    private enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }
    
    private struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    private var searchController: UISearchController = UISearchController(searchResultsController: nil)
    private var filterController: UISearchController = UISearchController(searchResultsController: nil)
    
    /// Secondary search results table view.
    //    internal var resultsTableController: ResultsTableController!
    //    internal var mediaSearchResultsViewController: MediaSearchResultsViewController!
    /// Restoration state for UISearchController
    private var restoredState = SearchControllerRestorableState()
    
    /// UISearchBar
    private var filterText: String? = nil
    
    private var lastProgressChangedUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()
    private var lastDownloadCompleteUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()
    private let bag = DisposeBag()
    private var keyboardBag = DisposeBag()
    private let keyboardDismissTapGestureRecognizer = UITapGestureRecognizer()
    private var userTappedDoneWhileFiltering: Bool = false
    private var networkUnreachable: Bool = false
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
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
        
        
        noResultLabel.text = NSLocalizedString("No Result Found", comment: "").l10n()
        noResultLabel.textAlignment = .center
        noResultLabel.font = UIFont.systemFont(ofSize: 32)
        noResultLabel.textColor = .gray
        noResultLabel.backgroundColor = .clear
        
        
        collectionView.addSubview(noResultLabel)
        noResultLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noResultLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            noResultLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            noResultLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -100),
            noResultLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noResultLabel.heightAnchor.constraint(equalToConstant: 300),
        ])
        
        
        let notificationCenter = NotificationCenter.default
        
        // MediaItemCell
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleUserDidTapMoreNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleUserDidTapCancelNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
        
        //        MediaItemCell.mediaItemCellUserDidTapRetryNotification
        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapRetryNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in

            os_log("notification: %{public}@", log: OSLog.data, String(describing: notification))
            
            if let uap: UserActionPlayable = notification.object as? UserActionPlayable,
                let mediaItem: MediaItem = self?.makeMediaItem(for: uap) {
                // clear-out from interrupted items
                self?.downloadListingViewModel.downloadInterruptedItems[mediaItem.uuid] = nil
                self?.downloadListingViewModel.fetchDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
            }
        }
        
        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            
            os_log("notification: %{public}@", log: OSLog.data, String(describing: notification))
            
            if let uap: UserActionPlayable = notification.object as? UserActionPlayable,
                let mediaItem: MediaItem = self?.makeMediaItem(for: uap) {
                self?.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlist_uuid)
            }
        }
        
        notificationCenter.addObserver(forName: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            os_log("notification: %{public}@", log: OSLog.data, String(describing: notification))
            
            if let uap: UserActionPlayable = notification.object as? UserActionPlayable,
                let mediaItem: MediaItem = self?.makeMediaItem(for: uap) {
                if let weakSelf = self,
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
                    } else if let downloading: FileDownload = weakSelf.downloadListingViewModel.downloadInterruptedItems[mediaItem.uuid] {
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
                        if fileDownload.progress == 1.0  {
                            actionController.addAction(Action(ActionData(title: "Share File...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                                
                                weakSelf.shareFile(mediaItem: mediaItem)
                            }))
                        }
                    }
                    actionController.addAction(Action(ActionData(title: "Share Link...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                        weakSelf.shareLink(mediaItem: mediaItem)
                    }))
                    
                    actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "yt-cancel-icon")!), style: .cancel, handler: nil))
                    
                    weakSelf.present(actionController, animated: true, completion: nil)
                }
            }
            
            
            //        if let fileDownload: FileDownload = notification.object as? FileDownload,
            //            let downloadAsset: Asset = self.downloadAsset.value {
            //            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
            //            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
            //
            //                self.downloadState.onNext(.initiating)
            //            }
            //
            //        }
            
        }
        // DownloadService
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(MediaHistoryViewController.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)
        
        /// SEARCH
        
        //        resultsTableController = ResultsTableController()
        
        //        let dependencyModule = AppDependencyModule()
        //
        //        let uiFactory = dependencyModule.resolver.resolve(UIFactory.self)!
        //        let mediaSearchResultsViewController: MediaSearchResultsViewController = uiFactory.makeMediaSearching(playlistId: viewModel.playlistUuid, mediaCategory: viewModel.mediaCategory)
        
        
        
        //        resultsTableController.tableView.delegate = self
        //        searchController = UISearchController(searchResultsController: resultsTableController)
        
        searchController = UISearchController(searchResultsController: mediaSearchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        searchController.searchBar.autocapitalizationType = .none
        //        searchController.dimsBackgroundDuringPresentation = true // The default is true.
        searchController.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        
        filterController.dimsBackgroundDuringPresentation = false
        filterController.searchBar.placeholder = NSLocalizedString("Filter", comment: "").l10n()
        filterController.searchResultsUpdater = self
        filterController.searchBar.delegate = self // Monitor when the search button is tapped.
        filterController.searchBar.autocapitalizationType = .none
        //        searchController.dimsBackgroundDuringPresentation = true // The default is true.
        filterController.delegate = self
        
        filterController.searchBar.enablesReturnKeyAutomatically = true
        filterController.searchBar.returnKeyType = .done
        //        filterController.searchBar.searchTextField.returnKeyType = .done
        
        
        // have view model capture uisearchbar keyboard events
        // for filter use case
        //        searchController.searchBar.rx.text
        //            .orEmpty
        //            .distinctUntilChanged()
        //            .debug()
        //            .bind(to: viewModel.filterText)
        //            .disposed(by: bag)
        
        // capture back the filterText to view controller
        // (may not need this)
        //        viewModel.filterText
        //            .observeOn(MainScheduler.instance)
        //            .subscribe { [unowned self] filterText in
        //                DDLogDebug("filterText: \(filterText)")
        //                if let text: String = filterText.element {
        //                    self.filterText = text
        //                }
        //            }
        //            .disposed(by: bag)
        
        // capture search button tap event
        searchController.searchBar.rx
            .searchButtonClicked
            .debug()
            .subscribe(onNext: { [unowned self] _ in
                if let searchText: String = self.searchController.searchBar.text {
                    //                    self.viewModel.searchText.value = searchText
                    self.mediaSearchResultsViewController.viewModel.searchText.value = searchText
                }
            })
            .disposed(by: bag)
        
        // observe changes on the searchedSections and refresh
        // search results if there are
        //        viewModel.searchedSections
        //            .asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .next { [unowned self] sections in
        //                self.viewModelSearchSections = sections
        //                self.resultsTableController.viewModelSearchSections = sections
        //                self.resultsTableController.tableView.reloadData()
        //            }.disposed(by: bag)
        
        //        mediaSearchResultsViewController.viewModel.sections
        //            .asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .next { [unowned self] sections in
        ////                self.viewModelSearchSections = sections
        //                self.mediaSearchResultsViewController.viewModelSections = sections
        ////                self.mediaSearchResultsViewController.collectionView.reloadData()
        //            }.disposed(by: bag)
        
        
        reactToViewModel()
        bindPlaybackViewModel()
        bindDownloadListingViewModel()
        setupKeyboardHandling()
        
    }
    
    // MARK: Private helpers
    
    func makeMediaItem(for userActionPlayable: UserActionPlayable) -> MediaItem {
        return MediaItem(content_provider_link: nil,
                         duration: userActionPlayable.duration,
                         hash_id: userActionPlayable.hash_id,
                         inserted_at: userActionPlayable.inserted_at,
                         ipfs_link: nil,
                         language_id: userActionPlayable.language_id,
                         large_thumbnail_path: userActionPlayable.large_thumbnail_path,
                         localizedname: userActionPlayable.localizedname,
                         med_thumbnail_path: userActionPlayable.med_thumbnail_path,
                         media_category: userActionPlayable.media_category,
                         medium: "audio",
                         multilanguage: userActionPlayable.multilanguage,
                         ordinal: userActionPlayable.ordinal,
                         path: userActionPlayable.path,
                         playlist_uuid: userActionPlayable.playlist_uuid,
                         presented_at: userActionPlayable.presented_at,
                         presenter_name: userActionPlayable.presenter_name,
                         published_at: userActionPlayable.published_at,
                         small_thumbnail_path: userActionPlayable.small_thumbnail_path,
                         source_material: userActionPlayable.source_material,
                         tags: userActionPlayable.tags,
                         track_number: userActionPlayable.track_number,
                         updated_at: userActionPlayable.updated_at,
                         uuid: userActionPlayable.playable_uuid)
        
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.keyboardEvents
            .next { [unowned self] (isHiding, frame) in
                let keyboardViewEndFrame = self.view.convert(frame, from: self.view.window)
                
                if isHiding {
                    self.collectionView.contentInset = UIEdgeInsets(top: 0,
                                                                    left: 0,
                                                                    bottom: 0,
                                                                    right: 0)
                    self.keyboardBag = DisposeBag()
                    
                    // removing because it interferes with cell selection
                    self.view.removeGestureRecognizer(self.keyboardDismissTapGestureRecognizer)
                } else {
                    self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
                    self.setupKeyboardDismissGestureRecognizer()
                }
        }
        .disposed(by: bag)
    }
    
    private func setupKeyboardDismissGestureRecognizer() {
        keyboardDismissTapGestureRecognizer.rx.event
            .next { [unowned self] _ in
                self.view.endEditing(true)
        }
        .disposed(by: keyboardBag)
        view.addGestureRecognizer(keyboardDismissTapGestureRecognizer)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        // https://stackoverflow.com/a/49033096
        
        /** Search presents a view controller by applying normal view controller presentation semantics.
         This means that the presentation moves up the view controller hierarchy until it finds the root
         view controller or one that defines a presentation context.
         */
        
        /** Specify that this view controller determines how the search controller is presented.
         The search controller should be presented modally and match the physical size of this view controller.
         */
        definesPresentationContext = true
        
        if self.viewModelSections.count > 0 && self.viewModelSections[0].items.count == 0 {
            viewModel.fetchAppendMedia.onNext(true)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }
    
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
    }
    
    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.filteredSections.asObservable()
            .observeOn(MainScheduler.instance)
            //            .debug()
            //            .filter{ $0[Constants.mediaSection].items.count > 0 }
            .next { [unowned self] sections in
                // first time loading sections
                if self.itemsUpdatedAtLeastOnce == false {
                    self.viewModelSections = sections
                    self.collectionView.reloadData()
                    self.itemsUpdatedAtLeastOnce = true
                }
                else {
                    if let myselfInTopViewController: Bool = self.navigationController?.topViewController?.children.contains(self)  {
                        // only update this list while view controller is visible
                        if myselfInTopViewController == true {
                            let currentItemsCount: Int = self.viewModelSections[Constants.mediaSection].items.count
                            let appendCount: Int = sections[Constants.mediaSection].items.count - currentItemsCount
                            os_log("currentItemsCount: %{public}@", log: OSLog.data, String(describing: currentItemsCount))
                            os_log("appendCount: %{public}@", log: OSLog.data, String(describing: appendCount))
                            
                            // we are filtering items since the count is reducing, just hard reloadData()
                            if appendCount <= 0 {
                                
                                DispatchQueue.main.async {
                                    UIView.performWithoutAnimation {
                                        self.viewModelSections = sections
                                        self.collectionView.reloadData()
                                    }
                                }
                            } else {
                                let newItems = Array(sections[Constants.mediaSection].items.suffix(appendCount))
                                os_log("newItems.count: %{public}@", log: OSLog.data, String(describing: newItems.count))
                                
                                let insertIndexPaths = Array(currentItemsCount...currentItemsCount + newItems.count-1).map { IndexPath(item: $0, section: Constants.mediaSection) }
                                os_log("insertIndexPaths: %{public}@", log: OSLog.data, String(describing: insertIndexPaths))
                                self.viewModelSections = sections
                                
                                DispatchQueue.main.async {
                                    //                            UIView.performWithoutAnimation {
                                    self.collectionView.performBatchUpdates({
                                        self.collectionView.insertItems(at: insertIndexPaths)
                                    }, completion: { result in
                                        self.collectionView.reloadData()
                                    })
                                    //                            }
                                }
                            }
                        }
                    }
                    //                     {
                    //                    }
                    
                }
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
        
        viewModel.networkStatus
            .asObservable()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .next { [unowned self] networkStatus in
                switch networkStatus {
                case .unknown:
                    os_log("MediaHistoryViewController networkStatus: %{public}@", log: OSLog.data, String(describing: networkStatus))
                    //                    self.searchController = UISearchController(searchResultsController: nil)
                    //                    self.searchController.searchBar.placeholder = NSLocalizedString("Filter", comment: "").l10n()
                    DispatchQueue.main.async {
                        self.navigationItem.searchController = self.filterController
                    }
                    
                case .notReachable:
                    self.networkUnreachable = true
                    os_log("MediaHistoryViewController networkStatus: %{public}@", log: OSLog.data, String(describing: networkStatus))
                    //                    self.searchController = UISearchController(searchResultsController: nil)
                    //                    self.searchController.searchBar.placeholder = NSLocalizedString("Filter", comment: "").l10n()
                    DispatchQueue.main.async {
                        self.navigationItem.searchController = self.filterController
                    }
                    
                    
                case .reachable(_):
                    os_log("MediaHistoryViewController networkStatus: %{public}@", log: OSLog.data, String(describing: networkStatus))
                    //                    self.searchController = UISearchController(searchResultsController: self.mediaSearchResultsViewController)
                    //                    self.searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "").l10n()
                    DispatchQueue.main.async {
                        if self.networkUnreachable == true {
                            self.searchController.isActive = true
                            self.filterController.isActive = false
                        }
                        self.navigationItem.searchController = self.searchController
                        
                        self.networkUnreachable = false
                        //                        self.navigationItem.searchController?.isActive = true
                    }
                }
        }.disposed(by: bag)
        
        viewModel.emptyFilteredResult.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] emptyResult in
                self.noResultLabel.isHidden = !emptyResult
        }.disposed(by: bag)

    }
    
    private func bindPlaybackViewModel() {
        playbackViewModel.playbackState
            .asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] playbackState in
                self.playbackState.value = playbackState
                
                if let previousSelectedPlayable: Playable = self.previousSelectedPlayable.value,
                    let indexPath: IndexPath = self.indexOfPlayableInViewModel(playable: previousSelectedPlayable) {
                    if indexPath.row >= 0 {
                        UIView.performWithoutAnimation {
                            self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                        }
                    }
                }
        }
        .disposed(by: bag)
        
        // playbackViewModel.playbackPlayable could either be a Playable or
        // a UserActionPlayable depending upon whether it was found in the
        // useractionplayable db table
        playbackViewModel.playbackPlayable
            .asObservable()
            .observeOn(MainScheduler.instance)
            .filterNils()
            .next { [unowned self] playable in
                guard let selectedPlayable: Playable = self.playbackViewModel.selectedPlayable.value else { return }
                
                if selectedPlayable is UserActionPlayable {
                    self.previousSelectedPlayable.value = self.selectedPlayable.value
                    self.selectedPlayable.value = selectedPlayable
                    
                    if let selected: Playable = self.selectedPlayable.value,
                        let indexPath: IndexPath = self.indexOfPlayableInViewModel(playable: selected) {
                        if indexPath.row >= 0 {
                            UIView.performWithoutAnimation {
                                self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                            }
                        }
                    }
                }
        }
        .disposed(by: bag)
        
    }
    
    private func bindDownloadListingViewModel() {
        Observable.combineLatest(downloadListingViewModel.activeFileDownloads().asObservable(),
                                 downloadListingViewModel.storedFileDownloads().asObservable())
            .subscribe(onNext: { activeDownloads, fileDownloads in
                os_log("activeDownloads: %{public}@", log: OSLog.data, String(describing: activeDownloads))
                os_log("fileDownloads: %{public}@", log: OSLog.data, String(describing: fileDownloads))
                

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
                        os_log("fileDownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
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
                os_log("interruptedDownloads: %{public}@", log: OSLog.data, String(describing: interruptedDownloads))

            }).disposed(by: bag)
        
        // the moment the viewmodel playlistuuid changes we
        // get the file downloads for that playlist
//        downloadListingViewModel.storedFileDownloads(for: viewModel.playlistUuid)
//            .asObservable()
//            .subscribe(onNext: { fileDownloads in
//
//                // put anything that is not .complete in downloadingItems
//                fileDownloads.forEach({ [unowned self] fileDownload in
//                    if fileDownload.state != .complete {
//                        //                        self.downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
//                    } else {
//                        self.downloadListingViewModel.downloadedItems[fileDownload.playableUuid] = fileDownload
//                    }
//                })
//
//                DDLogDebug("viewModel.playlistUuid: \(self.viewModel.playlistUuid) fileDownloads: \(fileDownloads)")
//            })
//            .disposed(by: bag)
        
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
                    
                    // remove it from downloadInterruptedItems
                    self.downloadListingViewModel.downloadInterruptedItems[uuid] = nil
                    
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
                os_log("=== fileDownloadDirty fileDownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
                let indexPath: IndexPath = self.indexOfFileDownloadInViewModel(fileDownload: fileDownload)
                os_log("=== fileDownloadDirty indexPath: %{public}@", log: OSLog.data, String(describing: indexPath))
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
    //    private func reactToContentSizeChange() {
    //        // Only dynamically change in iOS 11+. With iOS 10, user must re-launch app
    //        if #available(iOS 11, *) {
    //            NotificationCenter.default.rx
    //                .notification(NSNotification.Name.UIContentSizeCategoryDidChange)
    //                .next { [unowned self] _ in
    //                    // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
    //                    self.collectionView.collectionViewLayout.invalidateLayout()
    //                }
    //                .disposed(by: bag)
    //        }
    //    }
    
    // returns -1 on not found
    private func indexOfFileDownloadInViewModel(fileDownload: FileDownload) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        var index: Int = -1
        var indexPath: IndexPath = IndexPath(row: index, section: Constants.mediaSection)
        
        // assume section 0
        
        if viewModelSections.count > 0 {
            let items: [MediaListingItemType] = viewModelSections[Constants.mediaSection].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            if item is UserActionPlayable {
                                let actionPlayableItem: UserActionPlayable = item as! UserActionPlayable
                                return actionPlayableItem.playable_uuid == fileDownload.playableUuid
                            } else {
                                return item.uuid == fileDownload.playableUuid
                            }
                        }
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
            let items: [MediaListingItemType] = viewModelSections[Constants.mediaSection].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            return item.uuid == playable.uuid
                        }
                    }
                    
                }) ?? -1
            }
        }
        indexPath = IndexPath(row: index, section: Constants.mediaSection)
        return indexPath
    }
    
    // MARK: DownloadService notifications
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("MediaHistoryViewController initiateNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
            downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
            // try to find the indexPath of the media item and update
            // the progressevent with the indexPath so we can reload
            // a single row in the collectionView and avoid scrolling issues
            
            // assume section 0
            //            let items: [MediaListingItemType] = viewModelSections[0].items
            //            let index: Int = items.firstIndex(where: { item in
            ////                $0.uuid == fileDownload.playableUuid
            //
            //                switch item {
            //                case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
            //                    switch enumPlayable {
            //
            //                    case .playable(let item):
            ////                        drillInCell.set(uuid: item.uuid, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
            //
            //                        return item.uuid == fileDownload.playableUuid
            ////                        if let fileDownload: FileDownload = downloadingItems[item.uuid] {
            ////
            ////                        } else {
            ////                        }
            //                    }
            //                }
            //
            //            }) ?? -1
            
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("MediaHistoryViewController didProgressNotification fileDownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
            downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }
            
            //            lastProgressChangedUpdate.onNext(Date())
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("MediaHistoryViewController completeNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))
            
            downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
            
            // store download as `downloaded`
            downloadListingViewModel.downloadedItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
            //            lastProgressChangedUpdate.onNext(Date())
            //            lastDownloadCompleteUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastDownloadCompleteUpdate.onNext(indexPath)
            }
            
        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("MediaHistoryViewController errorNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))

            downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
            //            lastProgressChangedUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }
            
        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            os_log("MediaHistoryViewController cancelNotification filedownload: %{public}@", log: OSLog.data, String(describing: fileDownload))

            downloadListingViewModel.downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
            //            lastProgressChangedUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }
            
        }
    }
}

extension MediaHistoryViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        DDLogDebug("scrollViewDidEndDecelerating scrollView: \(scrollView)")
        
        if collectionView == scrollView {
            let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
            //        DDLogDebug("offset diff: \(offsetDiff)")
            os_log("near bottom: %{public}@", log: OSLog.data, String(describing: offsetDiff - collectionView.frame.size.height))

            //        if scrollView.contentSize.height - scrollView.contentOffset.y <
            
            if offsetDiff - collectionView.frame.size.height <= 20.0 {
                os_log("fetch!", log: OSLog.data)

//                viewModel.fetchAppendMedia.onNext(true)
            }
        }
    }
}


// MARK: UICollectionViewDelegateMagazineLayout

extension MediaHistoryViewController: UICollectionViewDelegateMagazineLayout {
    
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
        return 12
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 4, bottom: 24, right: 4)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 4, bottom: 24, right: 4)
    }
}

//extension MediaHistoryViewController {
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

// MARK: UISearchControllerDelegate

extension MediaHistoryViewController: UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        os_log("searchController: %{public}@", log: OSLog.data, String(describing: searchController))

    }
    
    public func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}

// MARK: UISearchBarDelegate

extension MediaHistoryViewController: UISearchBarDelegate {
    
    public override func resignFirstResponder() -> Bool {
        return true
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        os_log("searchBar: %{public}@", log: OSLog.data, String(describing: searchBar.text))
        
        if let textCount: Int = searchBar.text?.count {
            if searchBar == filterController.searchBar && textCount > 0 {
                // user tapped Done with text in the search bar,
                // which means they are done filtering. so set
                // flag to NOT clear the text but allow them to
                // resign keyboard
                
                userTappedDoneWhileFiltering = true
            }
        }
        searchBar.resignFirstResponder()
    }
    
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        
        return true
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar != filterController.searchBar && !userTappedDoneWhileFiltering {
            searchBar.setShowsCancelButton(false, animated: true)
            viewModel.filterText.onNext("")
            return true
            //            searchBar.resignFirstResponder()
        } else {
            searchBar.resignFirstResponder()
            return true
        }
        
        
        // reset the filteredMedia to no filtering to show the entire list
        // of content because they cancelled filtering
        //        viewModel.filterText.onNext("")
        //        return true
        //        var textHasChars: Bool = false
        //
        //        if let filterText: String = self.filterText {
        //            textHasChars = (filterText.count) > 0
        //        }
        //        return !textHasChars
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // the user ended filtering session, so clear it all out
        if searchBar == filterController.searchBar && userTappedDoneWhileFiltering {
            searchBar.setShowsCancelButton(false, animated: true)
            viewModel.filterText.onNext("")
            userTappedDoneWhileFiltering = false
        }
        searchBar.resignFirstResponder()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            os_log("probably cleared searchbar", log: OSLog.data)
            mediaSearchResultsViewController.viewModel.cancelSearch.value = searchText
        }
        viewModel.filterText.onNext(searchText)
        
        //        else {
        //            // we are looking for searchText.count > 0 for filtering because
        //            // we filter on the fly
        //            viewModel.filterText.onNext(searchText)
        //        }
    }
}

extension MediaHistoryViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        os_log("searchController: %{public}@", log: OSLog.data, String(describing: searchController))
        
        if let mediaSearchResultsViewController: MediaSearchResultsViewController =  searchController.searchResultsController as? MediaSearchResultsViewController {
            // reset "no result" label
            mediaSearchResultsViewController.viewModel.emptyResult.value = false
        }
    }
}

// MARK: - UIStateRestoration

extension MediaHistoryViewController {
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // Encode the view state so it can be restored later.
        
        // Encode the title.
        coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)
        
        // Encode the search controller's active state.
        coder.encode(searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        // Encode the first responser status.
        coder.encode(searchController.searchBar.isFirstResponder, forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Encode the search bar text.
        coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        // Restore the title.
        guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
            fatalError("A title did not exist. In your app, handle this gracefully.")
        }
        navigationItem.title! = decodedTitle
        
        /** Restore the active state:
         We can't make the searchController active here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        /** Restore the first responder status:
         Like above, we can't make the searchController first responder here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
    }
    
}
