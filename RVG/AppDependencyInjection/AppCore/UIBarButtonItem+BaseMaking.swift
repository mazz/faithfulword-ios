import UIKit

/// Base bar button items.
/// AVOID using `target` and `action`, instead,
/// 1.  Grab the button from here.
/// 2.  Hook up action via RxCocoa.  i.e. button.rx.tap( ...
///
/// Feature specific styles should live in their respective folders,
/// but should refer back to base style guide as much as pssible.
public extension UIBarButtonItem {
    public static func close() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage.uiAsset(name: "temp_x"),
                               style: .plain,
                               target: nil,
                               action: nil)
    }
    
    public static func settings() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage.uiAsset(name: "temp_settings"),
                               style: .plain,
                               target: nil,
                               action: nil)
    }

    public static func hamburger() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage.uiAsset(name: "menu"),
                               style: .plain,
                               target: nil,
                               action: nil)
    }

    public static func add() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage.uiAsset(name: "temp_+"),
                               style: .plain,
                               target: nil,
                               action: nil)
    }

    public static func back() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage.uiAsset(name: "icLeftChevron"),
                               style: .plain,
                               target: nil,
                               action: nil)
    }
//    public static func account() -> UIBarButtonItem {
//        return UIBarButtonItem(image: UIImage.uiAsset(name: "myGose-dark"),
//                               style: .plain,
//                               target: nil,
//                               action: nil)
//    }
    

//    public static func skip() -> UIBarButtonItem {
//        let skip = UIBarButtonItem(title: String.fetchUi("description_skip"),
//                                   style: .plain,
//                                   target: self,
//                                   action: nil)
//
//        let normalTitleAttributes = [NSAttributedStringKey.font: UIFont.dynamicGoseFont(.bold, .caption1),
//                                     NSAttributedStringKey.foregroundColor: UIColor.boseNavBarRightActionGrey]
//        skip.setTitleTextAttributes(normalTitleAttributes, for: .normal)
//
//        let highlightedTitleAttributes = [NSAttributedStringKey.font: UIFont.dynamicGoseFont(.bold, .caption1),
//                                          NSAttributedStringKey.foregroundColor: UIColor.boseNavBarRightActionGrey.withAlphaComponent(0.8)]
//        skip.setTitleTextAttributes(highlightedTitleAttributes, for: .highlighted)
//
//        return skip
//    }
    
}
