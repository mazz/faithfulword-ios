//
//  MediaSearchViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-31.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import GRDB

internal final class MediaDetailsViewModel {
    // MARK: Fields
    
    public func section(at index: Int) -> MediaDetailsSectionViewModel {
        return sections.value[index]
    }
    
    public func item(at indexPath: IndexPath) -> MediaDetailsItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }
    
    public var filterText: PublishSubject<String> = PublishSubject<String>()
    public var filterTextObservable: Observable<String> {
        return filterText.asObservable()
    }
    
    public var searchText: Field<String> = Field<String>("")
    
    //    public var searchValue: Field<String> = Field<String>("")
    //    var searchValueObservable: Observable<String> {
    //        return searchValue.asObservable()
    //    }
    
    // media filtered by search bar
    
    // media loaded on initial fetch
    public private(set) var media = Field<[Playable]>([])
    public private(set) var sections = Field<[MediaDetailsSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()
    
    public private(set) var playableItem = Field<Playable?>(nil)
    
    public var drillInEvent: Observable<MediaDetailsDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent
            .do(onNext: { [weak self] indexPath in
                let section = self?.sections.value[indexPath.section]
                let item = section?.items[indexPath.item]
                DDLogDebug("item: \(String(describing: item))")
                if case .drillIn(let type, _, _, _, _)? = item {
                    switch type {
                    case .playable(let item):
                        DDLogDebug("item: \(item)")
                        self?.assetPlaybackService.playableItem.value = item
                    }
                }
                
            })
            .filterMap { [weak self] indexPath -> MediaDetailsDrillInType? in
                let section = self?.sections.value[indexPath.section]
                let item = section?.items[indexPath.item]
                // Don't emit an event for anything that is not a 'drillIn'
                if case .drillIn(let type, _, _, _, _)? = item {
                    return type
                }
                return nil
        }
    }
    
    // MARK: Dependencies
    public let playable: Playable!
    private let assetPlaybackService: AssetPlaybackServicing!
    private let reachability: RxClassicReachable!
    // MARK: Fields
    
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private let bag = DisposeBag()
    
    internal init(
        playable: Playable,
        assetPlaybackService: AssetPlaybackServicing,
        reachability: RxClassicReachable) {
        self.playable = playable
        self.reachability = reachability
        self.assetPlaybackService = assetPlaybackService
        setupDatasource()
    }
    
    private func setupDatasource() {
        reactToReachability()
        
        // do fetch when network reachability is detected
        networkStatus.asObservable()
            //            .observeOn(MainScheduler.instance)
            .map({ status -> String in
                
                var outStatus: String = "unknown"
                switch status {
                    
                case .unknown:
                    outStatus = "unknown"
                case .notReachable:
                    outStatus = "notReachable"
                case .reachable(_):
                    outStatus = "reachable"
                }
                return outStatus
            })
            .filter { $0 == "reachable" || $0 == "notReachable"}
            .take(1)
            .next { [unowned self] status in
                DDLogDebug("take status: \(status)")
                //                self.initialFetch()
            }.disposed(by: self.bag)
        
        self.media.asObservable()
            .map { $0.map { playable -> MediaDetailsItemType in
                let icon: String!
                
                switch MediaCategory(rawValue: self.playable.media_category) {
                case .none:
                    icon = "none"
                case .some(.gospel):
                    icon = "feet"
                case .some(.livestream):
                    icon = "disc_icon_white"
                case .some(.motivation):
                    icon = "feet"
                case .some(.movie):
                    icon = "disc_icon_white"
                case .some(.music):
                    icon = "disc_icon_white"
                case .some(.podcast):
                    icon = "disc_icon_white"
                case .some(.preaching):
                    icon = "feet"
                case .some(.testimony):
                    icon = "feet"
                case .some(.tutorial):
                    icon = "feet"
                case .some(.conference):
                    icon = "disc_icon_white"
                case .some(.bible):
                    icon = "chapter"
                }
                var presenter: String = "Unknown Presenter"
                if let presenterName: String = playable.presenter_name {
                    presenter = presenterName
                }
                
                return MediaDetailsItemType.drillIn(type: .playable(item: playable), iconName: "none", title: playable.localizedname, presenter: presenter, showBottomSeparator: true)
                }
            }
            .next { [unowned self] names in
                
                var detailsSection: MediaDetailsSectionViewModel
                var mediaSection: MediaDetailsSectionViewModel
                
                if names.count > 0 {
                    // details section
                    if let mediaItem: MediaItem = self.playable as? MediaItem {
                        // media section
                        detailsSection = MediaDetailsSectionViewModel(type: .details, items: [MediaDetailsItemType.details(playable: mediaItem, presentedAt: mediaItem.presented_at, showBottomSeparator: true)])
//                        self.sections.value.append(MediaDetailsSectionViewModel(type: .details, items: [MediaDetailsItemType.details(playable: mediaItem, presentedAt: mediaItem.presentedAt, showBottomSeparator: true)]))
                        mediaSection = (MediaDetailsSectionViewModel(type: .media, items: names))
//                        self.sections.value.append(MediaDetailsSectionViewModel(type: .media, items: names))
                        
                        self.sections.value = [detailsSection, mediaSection]
                    }
                    
                } else {
                    self.sections.value = []
                }
            }.disposed(by: bag)
        
        // assignment to self.media will generate sectionmodel
        self.media.value = [self.playable]
    }
    
    private func reactToReachability() {
        self.reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                switch networkStatus {
                case .unknown:
                    DDLogDebug("MediaDetailsViewModel \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("MediaDetailsViewModel \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("MediaDetailsViewModel \(self.reachability.status.value)")
                }
            }).disposed(by: self.bag)
    }
}

