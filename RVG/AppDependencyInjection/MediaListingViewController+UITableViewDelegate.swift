//
//  MediaListingViewController+UITableViewDelegate.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-29.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

// MARK: - UITableViewDelegate

extension MediaListingViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlayable: Playable
        
        let item: MediaListingItemType = viewModelSearchSections[indexPath.section].items[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: BaseTableViewController.tableViewCellIdentifier, for: indexPath)
        
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator):
            //            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            switch enumPlayable {
                
            case .playable(let item):
                //                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
//                configureCell(cell, forPlayable: item)
                selectedPlayable = item
            }
            //            return drillInCell
        }
        

        
        // Set up the detail view controller to show.
        let detailViewController = DetailViewController.detailViewControllerForPlayable(selectedPlayable)

        navigationController?.pushViewController(detailViewController, animated: true)
        resultsTableController.tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - UITableViewDataSource

extension MediaListingViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BaseTableViewController.tableViewCellIdentifier, for: indexPath)
        
        let product = products[indexPath.row]
        configureCell(cell, forProduct: product)
        
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forProduct product: Product) {
        cell.textLabel?.text = product.title
        
        var numberFormatter = NumberFormatter()

        /** Build the price and year string.
         Use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice).
         */
        let priceString = numberFormatter.string(from: NSNumber(value: product.introPrice))
        
        cell.detailTextLabel?.text = "\(priceString!) | \(product.yearIntroduced)"
    }

}
