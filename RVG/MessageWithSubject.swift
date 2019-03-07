//
//  MessageWithSubject.swift
//  FaithfulWord
//
//  Created by Michael on 2019-03-06.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

class MessageWithSubject: NSObject, UIActivityItemSource {
    
    let subject:String
    let message:String
    
    init(subject: String, message: String) {
        self.subject = subject
        self.message = message
        
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return message
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return message
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}

