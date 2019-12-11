//
//  String+iso8601.swift
//  EvaluApp
//
//  Created by Michael on 2019-11-05.
//  Copyright © 2019 ilearningsolutions.ca. All rights reserved.
//

import Foundation

   /*
   Date().description(with: .current)   //  Tuesday, February 5, 2019 at 10:35:01 PM Brasilia Summer Time"
   let dateString = Date().iso8601      //  "2019-02-06T00:35:01.746Z"

   if let date = dateString.iso8601 {
    date.description(with: .current)    // "Tuesday, February 5, 2019 at 10:35:01 PM Brasilia Summer Time"
    print(date.iso8601)                 //  "2019-02-06T00:35:01.746Z\n"
   }
   */

extension String {
    var iso8601: Date? {
        return Formatter.iso8601.date(from: self)
    }
}

