//
//  DownloadServicing.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

protocol DownloadServicing {
    func fetchDownload() -> Single<Void>
}


public final class DownloadService {
    public init() { }
}


extension DownloadService: DownloadServicing {
    func fetchDownload() -> Single<Void> {
        print("fetchDownload")
        return Single.just(())
    }

}
