//
//  ContactUsModel.swift
//  RVG
//
//  Created by michael on 2017-05-28.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import Foundation

class ContactUsModel {
    
    var name: String
    var email: String
    var message: String
    var signup: Bool

    init(name: (String), email: (String), message: (String), signup: (Bool)) {
        self.name = name
        self.email = email
        self.message = message
        self.signup = signup
    }
}
