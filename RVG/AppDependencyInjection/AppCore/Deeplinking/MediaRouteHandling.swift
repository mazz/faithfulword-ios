//
//  MediaRouteHandling.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-04.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

public typealias MediaRoute = (uuid: String, route: String)
/// Protocol for handling deeplink URLs that open the app. Allows observers
/// to subscribe for deeplink events, and inspect the URL's host and query items
/// to determine whether the deeplink should be handled.
public protocol MediaRouteHandling {
    var mediaRouteEvent: Observable<MediaRoute> { get }
    
    func emitMediaRouteEvent(for route: String)
}

public final class MediaRouteHandler: MediaRouteHandling {
    public var mediaRouteEvent: Observable<MediaRoute> {
        return deeplinkSubject.asObservable()
    }
    private let deeplinkSubject = PublishSubject<MediaRoute>()
    
    public func emitMediaRouteEvent(for route: String) {
        guard let routeComponents: [String] = route.components(separatedBy: "/"),
        let mediaUuid: String = routeComponents.last else { return }
        deeplinkSubject.onNext((mediaUuid, route))
    }
}
