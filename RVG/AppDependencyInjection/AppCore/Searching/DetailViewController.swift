//
//  DetailViewController.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-30.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Constants
    
    // Constants for Storyboard/ViewControllers.
    private static let storyboardName = "Root"
    private static let viewControllerIdentifier = "DetailViewController"
    
    // Constants for state restoration.
    private static let restoreProduct = "restoreProductKey"
    private static let restorePlayable = "restorePlayableKey"

    // MARK: - Properties
    
    var product: Product!
    var playable: Playable!

    @IBOutlet private weak var presenterLabel: UILabel!
    @IBOutlet private weak var sourceLabel: UILabel!
    
    // MARK: - Initialization
    
    class func detailViewControllerForProduct(_ product: Product) -> UIViewController {
        let storyboard = UIStoryboard(name: DetailViewController.storyboardName, bundle: nil)
        
        let viewController =
            storyboard.instantiateViewController(withIdentifier: DetailViewController.viewControllerIdentifier)
        
        if let detailViewController = viewController as? DetailViewController {
            detailViewController.product = product
        }
        
        return viewController
    }

    class func detailViewControllerForPlayable(_ playable: Playable) -> UIViewController {
        let storyboard = UIStoryboard(name: DetailViewController.storyboardName, bundle: nil)
        
        let viewController =
            storyboard.instantiateViewController(withIdentifier: DetailViewController.viewControllerIdentifier)
        
        if let detailViewController = viewController as? DetailViewController {
            detailViewController.playable = playable
        }
        
        return viewController
    }

    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
        
        title = playable.localizedname
        
        presenterLabel.text = playable.presenterName ?? "Unknown" //"\(String(describing: playable.presenterName))"
        
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = .currency
//        numberFormatter.formatterBehavior = .default
//        let priceString = numberFormatter.string(from: NSNumber(value: product.introPrice))
        sourceLabel.text = playable.sourceMaterial
    }
    
}

// MARK: - UIStateRestoration

extension DetailViewController {
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // Encode the product.
//        coder.encode(playable, forKey: DetailViewController.restoreProduct)
        coder.encode(playable, forKey: DetailViewController.restorePlayable)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        // Restore the product.
        if let decodedPlayable = coder.decodeObject(forKey: DetailViewController.restoreProduct) as? Playable {
            playable = decodedPlayable
        } else {
            fatalError("A playable did not exist. In your app, handle this gracefully.")
        }
    }
    
}
