//
//  MediaFilterResultsViewController.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-08.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MagazineLayout

class MediaFilterResultsViewController: UIViewController, UICollectionViewDataSource /* , UICollectionViewDelegate */ {
    
    internal lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        //        collectionView.register(UINib(nibName: "SearchResultsCell", bundle: nil), forCellWithReuseIdentifier: SearchResultsCell.description())
        collectionView.register(UINib(nibName: "MediaItemSearchResultsCell", bundle: nil), forCellWithReuseIdentifier: MediaItemSearchResultsCell.description())
        
        collectionView.isPrefetchingEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        return collectionView
    }()
    
    // MARK: Dependencies
    
    internal var viewModel: MediaSearchViewModel!
    
    // MARK: Fields
    let noResultLabel: UILabel = UILabel(frame: .zero)
    
    internal var viewModelSections: [MediaListingSectionViewModel] = []
    
    //    internal var searchViewModel: MediaSearchViewModel!
    
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
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        //        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Do any additional setup after loading the view.
        
        //        self.noResultFoundLabel.text = NSLocalizedString("No Result Found", comment: "").l10n()
        
        reactToViewModel()
    }
    
    
    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.searchedSections.asObservable()
            .observeOn(MainScheduler.instance)
            //            .filter{ $0[0].items.count > 0 }
            .next { [unowned self] sections in
                // first time loading sections
                //                if self.itemsUpdatedAtLeastOnce == false {
                self.viewModelSections = sections
                self.collectionView.reloadData()
                //                    self.itemsUpdatedAtLeastOnce = true
                //                }
                //                else {
                //                    let currentItemsCount: Int = self.viewModelSections[0].items.count
                //                    let appendCount: Int = sections[0].items.count - currentItemsCount
                //                    let newItems = Array(sections[0].items.suffix(appendCount))
                //                    DDLogDebug("newItems.count: \(newItems.count)")
                //
                //                    let insertIndexPaths = Array(currentItemsCount...currentItemsCount + newItems.count-1).map { IndexPath(item: $0, section: 0) }
                //                    DDLogDebug("insertIndexPaths: \(insertIndexPaths)")
                //                    self.viewModelSections = sections
                //
                //                    DispatchQueue.main.async {
                //                        self.collectionView.performBatchUpdates({
                //                            self.collectionView.insertItems(at: insertIndexPaths)
                //                        }, completion: { result in
                //                            self.collectionView.reloadData()
                //                        })
                //                    }
                //                }
            }.disposed(by: bag)
        
        viewModel.emptyResult.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] emptyResult in
                self.noResultLabel.isHidden = !emptyResult
            }.disposed(by: bag)
        
    }
}

extension MediaFilterResultsViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        DDLogDebug("scrollViewDidEndDecelerating scrollView: \(scrollView)")
        
        if collectionView == scrollView {
            let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
            //        DDLogDebug("offset diff: \(offsetDiff)")
            DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
            //        if scrollView.contentSize.height - scrollView.contentOffset.y <
            
            if offsetDiff - collectionView.frame.size.height <= 20.0 {
                DDLogDebug("fetch!")
                //                viewModel.fetchMoreMedia()
                viewModel.fetchAppendSearch.onNext(true)
            }
        }
    }
}

// MARK: UICollectionViewDelegateMagazineLayout

extension MediaFilterResultsViewController: UICollectionViewDelegateMagazineLayout {
    
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


extension MediaFilterResultsViewController: UICollectionViewDelegate {
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
    //            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemSearchResultsCell.description(), for: indexPath) as! MediaItemSearchResultsCell
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
        let item: MediaListingItemType = viewModelSections[indexPath.section].items[indexPath.row]
        
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemSearchResultsCell.description(), for: indexPath) as! MediaItemSearchResultsCell
            switch enumPlayable {
                
            case .playable(let item):
                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator)
                
            }
            return drillInCell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
    
    
}

