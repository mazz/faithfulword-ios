//
//  OrgResponse.swift
//  FaithfulWord
//
//  Created by Michael on 2019-05-06.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

public struct OrgResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Org]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}


//{
//    "pageNumber": 1,
//    "pageSize": 50,
//    "result": [
//    {
//    "bannerPath": null,
//    "basename": "faithfulwordapp",
//    "insertedAt": "2019-05-04T23:33:39Z",
//    "largeThumbnailPath": null,
//    "medThumbnailPath": null,
//    "shortname": "faithfulwordapp",
//    "smallThumbnailPath": null,
//    "updatedAt": "2019-05-04T23:33:39Z",
//    "uuid": "53af6fa2-b9e3-4ee5-a84f-eb141443852a"
//    }
//    ],
//    "status": "success",
//    "totalEntries": 1,
//    "totalPages": 1,
//    "version": "1.3"
//}
