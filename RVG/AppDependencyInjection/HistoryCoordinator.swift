//
//  HistoryCoordinator.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-08.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class HistoryCoordinator  {
    // MARK: Dependencies
    
    internal let uiFactory: AppUIMaking
    
    // MARK: Fields
    private let bag = DisposeBag()
    
    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension HistoryCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        let historyController = uiFactory.makeHistoryPage()
        setup(historyController)
    }
}
