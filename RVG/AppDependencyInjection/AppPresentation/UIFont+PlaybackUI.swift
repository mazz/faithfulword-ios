//
//  UIFont+PlaybackUI.swift
//  FaithfulWord
//
//  Created by Michael on 2019-03-15.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation

private let songTitleFontSize: CGFloat = 23.0

extension UIFont {
    public class func songTitleFont() -> UIFont {
        let fontFamilyName = UIFont(name: "Helvetica Neue", size: songTitleFontSize)?.familyName ?? UIFont.systemFont(ofSize: songTitleFontSize).familyName
            let descriptorDictionary = [UIFontDescriptor.AttributeName.family: fontFamilyName, UIFontDescriptor.AttributeName.face: "Bold"]
            let fontDescriptor = UIFontDescriptor(fontAttributes: descriptorDictionary)
        return UIFont(descriptor: fontDescriptor, size: songTitleFontSize)
    }

    public class func artistNameFont() -> UIFont {
        let fontFamilyName = UIFont(name: "Helvetica Neue", size: songTitleFontSize)?.familyName ?? UIFont.systemFont(ofSize: songTitleFontSize).familyName
        let descriptorDictionary = [UIFontDescriptor.AttributeName.family: fontFamilyName, UIFontDescriptor.AttributeName.face: "Regular"]
        let fontDescriptor = UIFontDescriptor(fontAttributes: descriptorDictionary)
        return UIFont(descriptor: fontDescriptor, size: songTitleFontSize)
    }

}
