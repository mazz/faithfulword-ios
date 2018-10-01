//
//  Color+Image.swift
//  FaithfulWord
//
//  Created by Michael on 2018-09-30.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation


extension UIColor {
    func image(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image(actions: { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        })
    }
}

