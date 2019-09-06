//
//  MediaListingViewController+UICollectionViewDelegate.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-30.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

extension MediaListingViewController: UICollectionViewDelegate {
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
        let item: MediaListingItemType = viewModelSections[indexPath.section].items[indexPath.row]
        
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            switch enumPlayable {
                
            case .playable(let item):
                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator)
                
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
                
                if let fileDownload: FileDownload = downloadingItems[item.uuid] {
                    
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
                        self.downloadingItems[item.uuid] = nil
                        
                    case .complete:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadingItems[item.uuid] = nil
                        
                    case .error:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                        drillInCell.downloadStateButton.isHidden = false
                        drillInCell.downloadStateButton.isEnabled = false
                        drillInCell.downloadStateButton.setImage(UIImage(contentsOfFile: DownloadStateTitleConstants.errorRetryFile), for: .normal)
                        
                        // remove it from downloadingItems
                        self.downloadingItems[item.uuid] = nil
                        
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
                
                if let fileDownload: FileDownload = downloadedItems[item.uuid] {
                    drillInCell.progressView.isHidden = true
                    drillInCell.amountDownloaded.isHidden = false
                    
                    drillInCell.amountDownloaded.text = (fileDownload.progress == 1.0) ? fileSizeFormattedString(for: fileDownload.completedCount) : String(describing: " \(fileSizeFormattedString(for: fileDownload.completedCount))) / \(fileSizeFormattedString(for: fileDownload.totalCount)))")
                    drillInCell.downloadStateButton.isHidden = false
                    drillInCell.downloadStateButton.isEnabled = false
                    drillInCell.downloadStateButton.setImage(UIImage(named: DownloadStateTitleConstants.completedFile), for: .normal)
                } else {
                    // if we just deleted the file, update the UI
                    
                    // make sure that it is not in the downloading items
                    if let _: FileDownload = downloadingItems[item.uuid] {
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
            }
            return drillInCell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
    

}
