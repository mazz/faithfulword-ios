//
//  AnyObserverMaking.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-06.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

public final class AnyObserverMaking {

    /// A helper method for instantiating an observer with action to perform on next.
    ///
    /// - Parameter next: The action to be performed on next.
    /// - Returns: A freshly instantiated observer.
    public static func with<T>(next: @escaping (T) -> Void) -> AnyObserver<T> {
        return AnyObserver<T> { event in
            switch event {
            case .next(let element):
                next(element)
            default:
                break
            }
        }
    }

}
