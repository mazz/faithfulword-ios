
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
        return EnvironmentUrlItemKey(rawValue: "https://faithfulword.app")
//        return EnvironmentUrlItemKey(rawValue: "https://japheth.ca")
//        return EnvironmentUrlItemKey(rawValue: "https://markably.app")
//        return EnvironmentUrlItemKey(rawValue: "http://192.168.0.10")
        //192.168.0.10
    }
    static var LocalServerRootUrl: EnvironmentUrlItemKey {
        //
//        return EnvironmentUrlItemKey(rawValue: "http://mhanna-mbp15.local:4000")
//        return EnvironmentUrlItemKey(rawValue: "http://192.168.0.10:4000")
        return EnvironmentUrlItemKey(rawValue: "http://192.168.2.22:4000")
//        return EnvironmentUrlItemKey(rawValue: "http://192.168.0.17:4000")
//        192.168.2.22
//        return EnvironmentUrlItemKey(rawValue: "http://172.20.10.2:4000")
        
//        return EnvironmentUrlItemKey(rawValue: "http://192.168.2.22:4000")
//        return EnvironmentUrlItemKey(rawValue: "http://127.0.0.1:4000")
    }
    static var S3BaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://rvg-tracks-cdn.s3.amazonaws.com")
    }
    static var S3WestBaseUrl: EnvironmentUrlItemKey {
        return EnvironmentUrlItemKey(rawValue: "https://s3-us-west-2.amazonaws.com/rvg-tracks-cdn")
    }
}
