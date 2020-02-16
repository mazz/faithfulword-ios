//
//  MediaUniversalLinkHandling.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-12.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import os.log

public typealias MediaUniversalLink = (hashId: String, universalLink: String)
/// Protocol for handling deeplink URLs that open the app. Allows observers
/// to subscribe for deeplink events, and inspect the URL's host and query items
/// to determine whether the deeplink should be handled.
public protocol MediaUniversalLinkHandling {
    var mediaUniversalLinkEvent: Observable<MediaUniversalLink> { get }
    
    func emitMediaUniversalLinkEvent(for route: String)
}

public final class MediaUniversalLinkHandler: MediaUniversalLinkHandling {
    public var mediaUniversalLinkEvent: Observable<MediaUniversalLink> {
        return deeplinkSubject.asObservable()
    }
    private let deeplinkSubject = PublishSubject<MediaUniversalLink>()
    
    public func emitMediaUniversalLinkEvent(for universalLink: String) {
        os_log("emitMediaUniversalLinkEvent = %{public}@", log: OSLog.data, String(describing: universalLink))

        guard let linkComponents: [String] = universalLink.components(separatedBy: "/"),
            let hashId: String = linkComponents.last else { return }
        os_log("emitMediaUniversalLinkEvent onNext = %{public}@", log: OSLog.data, String(describing: hashId))
        deeplinkSubject.onNext((hashId, universalLink))
    }
}

