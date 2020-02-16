import UIKit
import AVFoundation
import Firebase
import Moya
import UserNotifications
import L10n_swift
import RxSwift
import Fabric
import Crashlytics
import LNPopupController
import CocoaLumberjack
import GRDB
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// Logs the view cycles like viewDidLoad.
    static let viewCycle = OSLog(subsystem: subsystem, category: "viewcycle")
    static let data = OSLog(subsystem: subsystem, category: "general")
}

// The shared database pool
var dbPool: DatabasePool!

// store launch info if the app was launched via push/deeplink and
// the main coordinator has not yet started handling media routes
var launchUserinfo: [AnyHashable: Any]?
// store url if the app was launched via push/deeplink and
// the main coordinator has not yet started handling media universal links
var userActivityUrl: URL?
var launchedWithUserActivity: Bool?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate /*, UNUserNotificationCenterDelegate, MessagingDelegate */ {
    static let applicationWillTerminate = Notification.Name("applicationWillTerminate")
    
    var window: UIWindow?
    private static var lastPushNotificationCheck = "lastPushNotificationCheck"
    let gcmMessageIDKey = "gcm.message_id"
    
    private let dependencyModule = AppDependencyModule()
    private lazy var appCoordinator: AppCoordinator = { [unowned self] in
        self.dependencyModule.resolver.resolve(AppCoordinator.self)!
        }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        try! setupDatabase(application)
        
        setupDeviceInfoCache()
        
        DDLog.add(DDTTYLogger.sharedInstance)
        DDTTYLogger.sharedInstance.colorsEnabled = true
        
        NSLog("faithful")
        os_log("faithful os_log", log: OSLog.data, type: .debug)
        
        // check the launch options to see if the app was launched from a non-backgrounded state
        // AND it was initiated by a push notification/deeplink
        //
        // STORE the push in launchUserinfo
        // once MainCoordinator has finished it's .flow(), it will post a .mainCoordinatorFlowDidCompleteNotification
        // on receipt of mainCoordinatorFlowDidCompleteNotification, we will do the MediaRoute
        
        if launchOptions != nil {
            let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification]
            if userInfo != nil {
                os_log("UIApplication.LaunchOptionsKey.remoteNotification: %{public}@", log: OSLog.data, String(describing: userInfo))
                let userinfoDict: [AnyHashable: Any] = userInfo as! [AnyHashable : Any]
                
                launchUserinfo = userinfoDict
            }
        }
        
        if let _ = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] {
            launchedWithUserActivity = true
        } else {
            launchedWithUserActivity = false
        }
        
        LNPopupBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).marqueeScrollEnabled = true
        
        UINavigationBar.appearance().tintColor = UIColor.black
        
        appCoordinator.flow(with: { initialViewController in
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }, completion: { _ in },
           context: .other)
        
        Fabric.with([Crashlytics.self])
        
        //        setupAudioSession()
        
        self.optInForPushNotifications(application: UIApplication.shared)
        
        NotificationCenter.default.addObserver(forName: MainCoordinator.mainCoordinatorFlowDidCompleteNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            DDLogDebug("notification: \(notification)")
            if let userinfoDict = launchUserinfo {
                self?.doMediaRoute(userinfoDict: userinfoDict)
            }
            
            if let url = userActivityUrl {
                if let launched = launchedWithUserActivity {
                    if launched {
                        self?.doMediaUniveralLinkRoute(url: url)
                    }
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        os_log("didUpdate", log: OSLog.data)
        os_log("userActivity.webpageURL = %@", log: OSLog.data, String(describing: userActivity.webpageURL))
        os_log("userActivity.userInfo = %@", log: OSLog.data, String(describing: userActivity.userInfo))

    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Get URL components from the incoming user activity
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }

        os_log("userActivity.webpageURL = %@", log: OSLog.data, String(describing: userActivity.webpageURL))

        // Check for specific URL components that you need
        guard let path = components.path else { return false }

        os_log("path = %@", log: OSLog.data, String(describing: path))
        
        

//        if let albumName = params.first(where: { $0.name == "albumname" } )?.value,
//            let photoIndex = params.first(where: { $0.name == "index" })?.value {
//            print("album = \(albumName)")
//            print("photoIndex = \(photoIndex)")
        
        if let url = userActivity.webpageURL {
            
            // in case the app launched with userActivity
            // store the URL and check back with an NSNotification
            // that is initiated by the main coordinator
            if let launched = launchedWithUserActivity {
                if launched {
                    userActivityUrl = url
                    return false
                }
            } else {
                doMediaUniveralLinkRoute(url: url)
                return true
            }
        } else {
            return false
        }

        return false
//        } else {
//            print("Either album name or photo index missing")
//            return false
//        }
    }
    
    private func doMediaRoute(userinfoDict: [AnyHashable: Any]) {
        os_log("userinfoDict: %{public}@", log: OSLog.data, String(describing: userinfoDict))
        if let deeplinkRoute: String = userinfoDict["deep_link_route"] as? String,
            let mediaType: String =  userinfoDict["media_type"] as? String,
            let mediaUuid: String =  userinfoDict["media_uuid"] as? String {
            
            os_log("deeplinkRoute = %@", log: OSLog.data, deeplinkRoute)
            os_log("mediaType = %@", log: OSLog.data, mediaType)
            os_log("mediaUuid = %@", log: OSLog.data, mediaUuid)
            
            if mediaType == "media_item" {
                var mediaRouteHandler = self.dependencyModule.resolver.resolve(MediaRouteHandling.self)!
                
                os_log("mediaRouteHandler = %{public}@", log: OSLog.data, String(describing: mediaRouteHandler))
                mediaRouteHandler.emitMediaRouteEvent(for: deeplinkRoute)
            }
        }
    }
    
    private func doMediaUniveralLinkRoute(url: URL) {
        os_log("doMediaUniveralLinkRoute: %{public}@", log: OSLog.data, String(describing: url))

        let urlString: String = url.absoluteString
        var mediaUniversalLinkHandler = self.dependencyModule.resolver.resolve(MediaUniversalLinkHandling.self)!
        
        os_log("mediaUniversalLinkHandler = %{public}@", log: OSLog.data, String(describing: mediaUniversalLinkHandler))
        mediaUniversalLinkHandler.emitMediaUniversalLinkEvent(for: urlString)

    }

    private func setupDatabase(_ application: UIApplication) throws {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let databasePath = documentsDirectory.appendingPathComponent("db.sqlite")
        dbPool = try DataStore.openDatabase(atPath: databasePath.path)
        
        // Be a nice iOS citizen, and don't consume too much memory
        // See https://github.com/groue/GRDB.swift/blob/master/README.md#memory-management
        dbPool.setupMemoryManagement(in: application)
    }
    
    private func setupDeviceInfoCache() {
        let deviceInfo = dependencyModule.resolver.resolve(DeviceInfoProviding.self)!
        UserDefaults.standard.set(deviceInfo.userAgent, forKey: "device_user_agent")
    }
    
    func optInForPushNotifications(application: UIApplication) {
        os_log("optInForPushNotifications", log: OSLog.data)
        
        UserDefaults.standard.set(Date(), forKey: AppDelegate.lastPushNotificationCheck)
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, error) in
            guard error == nil else {
                os_log("%@", log: OSLog.data ,String(describing: error!.localizedDescription))
                return
            }
        }
        
        //get application instance ID
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                os_log("Error fetching remote instance ID: %@", log: OSLog.data, String(describing: error))
            } else if let result = result {
                os_log("Remote instance ID token: %@", log: OSLog.data, String(describing: result.token))
            }
        }
        
        application.registerForRemoteNotifications()
    }
    
    
    private func setupAudioSession() {
        // Setup AVAudioSession to indicate to the system you how intend to play audio.
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            //            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            //            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP,
            //                                                                              .duckOthers,
            //                                                                              .defaultToSpeaker])
            
            //            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP,
            //                                                                              .duckOthers,
            //                                                                              .defaultToSpeaker])
            
            //            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default [.allowBluetooth, .mixWithOthers, .defaultToSpeaker])
            
        }
        catch {
            os_log("An error occured setting the audio session category: %@", log: OSLog.data, String(describing: error))
        }
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        os_log("didRegisterForRemoteNotificationsWithDeviceToken", log: OSLog.data)
        
        // Convert token to string
        let str = deviceToken.map { String(format: "%02X", $0) }.joined()
        //        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        // Print it to console
        os_log("APNs device token: %@", log: OSLog.data, str)
        
        Messaging.messaging().setAPNSToken(deviceToken, type: MessagingAPNSTokenType.unknown)
        os_log("APNs device token: %@", log: OSLog.data, String(describing: Messaging.messaging().apnsToken))
        if let firebaseToken = Messaging.messaging().fcmToken {
            os_log("FCM token: %@", log: OSLog.data, String(describing: firebaseToken))
            
            let deviceInfo = dependencyModule.resolver.resolve(DeviceInfoProviding.self)!
            
            if let apnsToken = Messaging.messaging().apnsToken {
                let apnsTokenString = apnsToken.map { String(format: "%02X", $0) }.joined()
                self.updatePushToken(fcmToken: firebaseToken,
                                     apnsToken: apnsTokenString,
                                     preferredLanguage: L10n.shared.preferredLanguage,
                                     userAgent: deviceInfo.userAgent, userVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, userUuid: NSUUID().uuidString)
            }
        }
    }
    
    func updatePushToken(fcmToken: String,
                         apnsToken: String,
                         preferredLanguage: String,
                         userAgent: String,
                         userVersion: String,
                         userUuid: String) {
        os_log("updatePushToken", log: OSLog.data)
        
        let provider = MoyaProvider<FwbcApiService>()
        // deviceUniqueIdentifier: String, apnsToken: String, fcmToken: String, nonce:
        provider.request(.pushTokenUpdate(fcmToken: fcmToken,
                                          apnsToken: apnsToken,
                                          preferredLanguage: preferredLanguage,
                                          userAgent: userAgent, userVersion: userVersion, userUuid: userUuid, orgId: 1)) { result in
                                            switch result {
                                            case let .success(moyaResponse):
                                                do {
                                                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                                                    let data = moyaResponse.data
                                                    //                    var parsedObject: BookResponse
                                                    
                                                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                                                    os_log("json: %@", log: OSLog.data, String(describing: json))
                                                    if let jsonObject = json as? [String:Any] {
                                                        os_log("jsonObject: %@", log: OSLog.data, String(describing: jsonObject))
                                                    }
                                                }
                                                catch {
                                                    os_log("pushTokenUpdate error: %@", log: OSLog.data, String(describing: error))
                                                }
                                                
                                            case let .failure(error):
                                                os_log(".failure: %@", log: OSLog.data, String(describing: error))
                                                // this means there was a network failure - either the request
                                                // wasn't sent (connectivity), or no response was received (server
                                                // timed out).  If the server responds with a 4xx or 5xx error, that
                                                // will be sent as a ".success"-ful response.
                                                //                errorClosure(error)
                                                os_log(".failure", log: OSLog.data)
                                            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        os_log("userNotificationCenter didReceive", log: OSLog.data)
        os_log("userNotificationCenter Handle push from background or closed response: %{public}@", log: OSLog.data, response)
        //        os_log("faithful os_log", log: OSLog.data, type: .debug)
        //        DDLogDebug("userNotificationCenter Handle push from background or closed response: \(response)")
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        os_log("userNotificationCenter Handle push from background or closed response userInfo: %{public}@", log: OSLog.data, response.notification.request.content.userInfo)
        
        //        launchUserinfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            os_log("Message Closed")
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            os_log ("App is Open")
            os_log("deep link route: %@", log: OSLog.data, String(describing: response.notification.request.content.userInfo["deep_link_route"]))
            
            let userinfoDict: [AnyHashable: Any] = response.notification.request.content.userInfo as! [AnyHashable : Any]
            self.doMediaRoute(userinfoDict: userinfoDict)
        }
        
        // Else handle any custom actions. . .
        completionHandler()
    }
    
    // handle notifications while in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        os_log("userNotificationCenter willPresent", log: OSLog.data)
        os_log("userNotificationCenter Handle push from foreground notification: %{public}@", log: OSLog.data, String(describing: notification))
        os_log("userNotificationCenter Handle push from foreground response notification.request.content.userInfo: %{public}@", log: OSLog.data, String(describing: notification.request.content.userInfo))
        
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        // Print the error to console (you should alert the user that registration failed)
        os_log("APNs registration failed: %@", log: OSLog.data, String(describing: error))
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        os_log("application didReceiveRemoteNotification", log: OSLog.data)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            os_log("Message ID: %@", log: OSLog.data, String(describing: messageID))
        }
        
        // Print full message.
        os_log("%@", log: OSLog.data, String(describing: userInfo))
        switch application.applicationState {
            
        case .inactive:
            os_log("Inactive")
            //Show the view with the content of the push
            completionHandler(.newData)
            
        case .background:
            os_log("Background")
            //Refresh the local model
            completionHandler(.newData)
            
        case .active:
            os_log("Active")
            //Show an in-app banner
            completionHandler(.newData)
        }
    }
    
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //        // Print notification payload data
    //        DDLogDebug("Push notification received: \(userInfo)")
    //        Messaging.messaging().appDidReceiveMessage(data)
    //
    //        completionHandler(UIBackgroundFetchResult)
    //
    //    }
    //    // Push notification received
    //    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
    //
    //
    //
    //    }
    
    //    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {
    //        print("Handle push from foreground")
    //        // custom code to handle push while app is in the foreground
    //        print("\(notification.request.content.userInfo)")
    //    }
    
    //    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    //        print("Handle push from background or closed")
    //        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
    //        print("\(response.notification.request.content.userInfo)")
    //    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        os_log("applicationWillResignActive", log: OSLog.data)
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        os_log("applicationDidEnterBackground", log: OSLog.data)
        //        Messaging.messaging().shouldEstablishDirectChannel = false
        //        os_log("Disconnected from FCM.")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        os_log("applicationWillEnterForeground", log: OSLog.data)
        
        application.applicationIconBadgeNumber = 0
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        os_log("applicationDidBecomeActive", log: OSLog.data)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        os_log("applicationWillTerminate", log: OSLog.data)
        NotificationCenter.default.post(name: AppDelegate.applicationWillTerminate, object: application)
        sleep(5)
        os_log("applicationWillTerminate sleep done")
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        os_log("messaging didRefreshRegistrationToken", log: OSLog.data)
        os_log("Firebase didRefreshRegistrationToken token")
        os_log("Firebase didRefreshRegistrationToken token: %@", log: OSLog.data, String(describing: fcmToken))
        if let apnsToken = Messaging.messaging().apnsToken {
            let apnsTokenString = apnsToken.map { String(format: "%02X", $0) }.joined()
            
            let deviceInfo = dependencyModule.resolver.resolve(DeviceInfoProviding.self)!
            
            self.updatePushToken(fcmToken: fcmToken,
                                 apnsToken: apnsTokenString,
                                 preferredLanguage: L10n.shared.preferredLanguage,
                                 userAgent: deviceInfo.userAgent,
                                 userVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                                 // TODO: cache User.uuid in product or a session service
                userUuid: NSUUID().uuidString)
        }
    }
    
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        os_log("messaging remoteMessage", log: OSLog.data)
        os_log("messaging remoteMessage.appData: %@", log: OSLog.data, String(describing: remoteMessage.appData))
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        os_log("messaging didReceiveRegistrationToken", log: OSLog.data)
        os_log("Firebase didRefreshRegistrationToken token: %@", log: OSLog.data, String(describing: fcmToken))
    }
}
