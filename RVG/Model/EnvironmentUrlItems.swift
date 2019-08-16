
import Foundation

extension EnvironmentUrlItemKey {
    static var ProductionServerRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://faithfulaudio.org")
    }
    static var ProductionFileStorageRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://d2v5mbm9qwqitj.cloudfront.net")
    }
    static var DevelopmentFileStorageRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://d2v5mbm9qwqitj.cloudfront.net")
    }
    static var DevelopmentServerRootUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://api.faithfulword.app")
    }
    static var LocalServerRootUrl: EnvironmentUrlItemKey {
        //
//        return EnvironmentUrlItemKey(rawValue: "http://mhanna-mbp15.local:4000")
        return EnvironmentUrlItemKey(rawValue: "http://192.168.0.13:4000")
//        return EnvironmentUrlItemKey(rawValue: "http://127.0.0.1:4000")
    }
    static var S3BaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://rvg-tracks-cdn.s3.amazonaws.com")
    }
    static var S3WestBaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://s3-us-west-2.amazonaws.com/rvg-tracks-cdn")
    }
}
