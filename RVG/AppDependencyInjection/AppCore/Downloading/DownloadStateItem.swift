//
//  DownloadStateItem.swift
//  FaithfulWord
//
//  Created by Michael on 2019-07-25.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

public final class DownloadStateItem {
    
    let downloadIdentifier: String
    let remoteUrl: URL
    var resumeData: Data? = nil
    var fileDownloadState: FileDownloadState = .initial
    var progress: HWIFileDownloadProgress? = nil
    var downloadError: Error? = nil
    var downloadErrorMessageStack: [String]? = nil
    var lastHttpStatusCode: Int? = nil
    
    init(downloadIdentifier: String, remoteUrl: URL) {
        self.downloadIdentifier = downloadIdentifier
        self.remoteUrl = remoteUrl
    }
}

/*
- (nonnull instancetype)initWithDownloadIdentifier:(nonnull NSString *)aDownloadIdentifier
remoteURL:(nonnull NSURL *)aRemoteURL;


@property (nonatomic, strong, readonly, nonnull) NSString *downloadIdentifier;
@property (nonatomic, strong, readonly, nonnull) NSURL *remoteURL;

@property (nonatomic, strong, nullable) NSData *resumeData;
@property (nonatomic, assign) DemoDownloadItemStatus status;

@property (nonatomic, strong, nullable) HWIFileDownloadProgress *progress;

@property (nonatomic, strong, nullable) NSError *downloadError;
@property (nonatomic, strong, nullable) NSArray<NSString *> *downloadErrorMessagesStack;
@property (nonatomic, assign) NSInteger lastHttpStatusCode;

- (nonnull DemoDownloadItem *)init __attribute__((unavailable("use initWithDownloadIdentifier:remoteURL:")));
+ (nonnull DemoDownloadItem *)new __attribute__((unavailable("use initWithDownloadIdentifier:remoteURL:")));

*/
