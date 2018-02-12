//
//  SideMenuHandling.swift
//  FaithfulWord
//
//  Created by Michael on 2018-02-12.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation

protocol SideMenuHandling {
    func goToCategoryFlow(categoryType: CategoryListingType)
    func goToExternalWebBrowser(url: URL)
    func goToMailComposer()
    func goToInlineWebBrowser(url: URL)
}

extension MainCoordinator: SideMenuHandling {
    func goToInlineWebBrowser(url: URL) {

    }

    func goToCategoryFlow(categoryType: CategoryListingType) {
        self.mainNavigationController.dismiss(animated: true, completion: {

            self.resettableCategoryListingCoordinator.value.categoryType = categoryType
            self.resettableCategoryListingCoordinator.value.mainNavigationController = self.mainNavigationController
            self.resettableCategoryListingCoordinator.value.flow(with: { viewController in
                self.mainNavigationController.pushViewController(
                    viewController,
                    animated: true
                )
            }, completion: { _ in
                self.mainNavigationController.dismiss(animated: true)
                self.resettableCategoryListingCoordinator.reset()
            }, context: .push(onto: self.mainNavigationController))

        })
    }

    func goToExternalWebBrowser(url: URL) {
        self.mainNavigationController.dismiss(animated: true) {
            UIApplication.shared.open(url, options: [:],
                                      completionHandler: nil)
        }
    }

    func goToMailComposer() {
        self.mainNavigationController.dismiss(animated: true, completion: {
            if let mailComposer = self.appUIMaking.makeMailComposer() {
                self.mainNavigationController.pushViewController(mailComposer,
                                                                 animated: true)
            } else {
                let okAlert = self.appUIMaking.makeOkAlert(
                    title: NSLocalizedString(
                        "Mail services are not available", comment: "").l10n(),
                    message: "")
                self.mainNavigationController.pushViewController(okAlert,
                                                                 animated: true)
            }
        })
    }


}


