//
//  Playable.swift
//  RVG
//
//  Created by maz on 2017-07-10.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

protocol Playable {
    var localizedName : String? { get set }
    var path : String? { get set }
    var presenterName : String? { get set }
    var sourceMaterial : String? { get set }

}
