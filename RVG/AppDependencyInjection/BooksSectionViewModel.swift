import Foundation
import RxDataSources

internal struct BooksSectionViewModel {
    internal let type: BooksSectionType
    internal let items: [BooksItemType]
}

internal enum BooksSectionType {
    case book
    case debug
}

internal enum BooksItemType {
//    case field(String, String)
//    case option(SettingOptionType)
//    case action(name: String)
    case drillIn(type: BooksDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
//    case info(String)
}

public enum BooksDrillInType {
    case defaultType
}


//public enum DeviceGroupItemType {
//    // Since only a single section, use regular cell for "header", to vastly simplify VC
//    case header(title: String, subtitle: String)
//    case nowPlaying(trackInfo: DeviceTrackInfoViewModel)
//    case drillIn(type: DeviceGroupDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
//}



//internal enum SettingOptionType {
//    case apSetup
//    case addProduct
//    case removeProduct
//    case manageMusicServices
//}

internal enum BookActionType {
    case openBook
}

extension BooksSectionViewModel: SectionModelType {
    typealias Item = BooksItemType
    init(original: BooksSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

//internal extension BooksSectionType {
//    internal var displayString: String {
//        switch self {
//        case .account: return String.fetch(Localizable.settingsAccountHeaderText)
//        case .manageProducts: return String.fetch(Localizable.settingsDevicesHeaderText)
//        case .manageMusicServices: return String.fetch(Localizable.settingsMusicServiceHeaderText)
//        case .appInfo: return "_APPLICATION_INFO"
//        case .debug: return "_DEBUG_OPTIONS"
//        }
//    }
//}

//internal extension SettingOptionType {
//    internal var displayString: String {
//        switch self {
//        case .apSetup: return String.fetch(Localizable.settingsDevicesApSetupOption)
//        case .addProduct: return String.fetch(Localizable.settingsDevicesAddOption)
//        case .removeProduct: return String.fetch(Localizable.settingsDevicesRemoveOption)
//        case .manageMusicServices: return String.fetch(Localizable.settingsMusicServiceManageOption)
//        }
//    }
//}

//internal extension BookActionType {
//    internal var displayString: String {
//        switch self {
//        case .logout: return String.fetch(Localizable.settingsAccountLogoutButtonText)
//        case .updateUser: return String.fetch(Localizable.settingsAccountUpdateUserButtonText)
//        }
//    }
//}

