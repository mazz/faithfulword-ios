/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

public struct Asset {
    
    // MARK: Types
    static let nameKey = "AssetName"
    static let uuidKey = "uuid"

    // MARK: Properties
    
    /// The name of the asset to present in the application.
    let name: String
    let artist: String
    let uuid: String
    let fileExtension: String
    // the initial location to seek to when playing
    let playbackPosition: Double
    let playbackRate: Float

    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    let urlAsset: AVURLAsset
}

/*
 public class Asset {

    // MARK: Types
    static let nameKey = "AssetName"

    // MARK: Properties

    /// The name of the asset to present in the application.
    var assetName: String

    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    var urlAsset: AVURLAsset

    init(assetName: String, urlAsset: AVURLAsset) {
        self.assetName = assetName
        self.urlAsset = urlAsset
    }
}
*/

