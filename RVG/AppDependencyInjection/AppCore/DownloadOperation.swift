//
//  DownloadOperation.swift
//  FaithfulWord
//
//  Created by Michael on 2019-07-07.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

public class DownloadOperation : Operation {
    
    private var task : URLSessionDownloadTask!
    
    enum OperationState : Int {
        case ready
        case executing
        case finished
    }
    
    // default state is ready (when the operation is created)
    private var state : OperationState = .ready {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            self.didChangeValue(forKey: "isExecuting")
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override public var isReady: Bool { return state == .ready }
    override public var isExecuting: Bool { return state == .executing }
    override public var isFinished: Bool { return state == .finished }
    
    init(session: URLSession, downloadTaskURL: URL) {
        super.init()
        /*
         set the operation state to finished once
         the download task is completed or have error
         */
//        self?.state = .finished
        
        // use weak self to prevent retain cycle
//        task = session.downloadTask(with
        
        task = session.downloadTask(with: downloadTaskURL)
        task.resume()

    }
    
    override public func start() {
        /*
         if the operation or queue got cancelled even
         before the operation has started, set the
         operation state to finished and return
         */
        if(self.isCancelled) {
            state = .finished
            return
        }
        
        // set the state to executing
        state = .executing
        
        print("downloading \(self.task.originalRequest?.url?.absoluteString ?? "")")
        
        // start the downloading
        self.task.resume()
    }
    
    override public func cancel() {
        super.cancel()
        
        // cancel the downloading
        self.task.cancel()
    }
}
