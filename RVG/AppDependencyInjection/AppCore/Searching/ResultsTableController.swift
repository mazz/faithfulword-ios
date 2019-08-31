/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The table view controller responsible for displaying the filtered products as the user types in the search field.
*/

import UIKit

class ResultsTableController: BaseTableViewController {
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return filteredProducts.count
        if viewModelSearchSections.count == 0 {
            return 0
        }
        return viewModelSearchSections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item: MediaListingItemType = viewModelSearchSections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BaseTableViewController.tableViewCellIdentifier, for: indexPath)
        
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
//            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            switch enumPlayable {
                
            case .playable(let item):
//                drillInCell.set(playable: item, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
                configureCell(cell, forPlayable: item)
            }
//            return drillInCell
        }
//        let product = filteredProducts[indexPath.row]
//        configureCell(cell, forProduct: product)
        
        return cell
    }
}
