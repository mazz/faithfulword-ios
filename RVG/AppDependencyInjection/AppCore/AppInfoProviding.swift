import Foundation

internal protocol AppInfoProviding {
    var versionDisplayString: String { get }
}

internal final class AppInfoProvider: AppInfoProviding {
    
//    private struct BuddyBuildPlistKey {
//        internal static let buildNumber = "BuddyBuildNumber"
//        internal static let branch = "BuddyBuildBranch"
//        internal static let prNumber = "BuddyBuildPullRequest"
//        internal static let baseBranch = "BuddyBuildBaseBranch"
//    }
    
    internal init() { }
    
    // MARK: <AppInfoProviding>
    
    internal var versionDisplayString: String {
        var environment = ""
        #if EXTERNAL
            environment = "external"
        #elseif RELEASE
            environment = "release"
        #elseif DEBUG
            environment = "debug"
        #endif
        
        let versionNumber = plistString(for: "CFBundleShortVersionString")!
        let buildNumber = plistString(for: "CFBundleVersion")!
        
        var appInfo = "\(versionNumber).\(buildNumber) \(environment)"
//        if let buddyBuildInfo = buddyBuildString() {
//            appInfo.append(" (\(buddyBuildInfo))")
//        }
        return appInfo
    }
    
    // MARK: Buddy build
    
//    private func buddyBuildString() -> String? {
//        guard var buddyBuildNumber = plistString(for: BuddyBuildPlistKey.buildNumber),
//            buddyBuildNumber.characters.count > 0 else {
//                return nil
//        }
//        guard var buddyBuildBranchInfo = plistString(for: BuddyBuildPlistKey.branch),
//            buddyBuildBranchInfo.characters.count > 0 else {
//                return buddyBuildNumber
//        }
//        if let pr = plistString(for: BuddyBuildPlistKey.prNumber),
//            let intoBranch = plistString(for: BuddyBuildPlistKey.baseBranch),
//            pr.characters.count > 0,
//            intoBranch.characters.count > 0 {
//            buddyBuildBranchInfo.append(" > \(intoBranch) pr#\(pr)")
//        }
//        return "#\(buddyBuildNumber) \(buddyBuildBranchInfo)"
//    }
    
    // MARK: Other helpers
    
    private func plistString(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
    
}
