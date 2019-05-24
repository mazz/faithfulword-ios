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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate /*, UNUserNotificationCenterDelegate, MessagingDelegate */ {

    var window: UIWindow?
    private static var lastPushNotificationCheck = "lastPushNotificationCheck"
    let gcmMessageIDKey = "gcm.message_id"
    
    private let dependencyModule = AppDependencyModule()
    private lazy var appCoordinator: AppCoordinator = { [unowned self] in
        self.dependencyModule.resolver.resolve(AppCoordinator.self)!
        }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(DDTTYLogger.sharedInstance)
        DDTTYLogger.sharedInstance.colorsEnabled = true

//        DDLogVerbose("Verbose")
//        DDLogDebug("Debug")
//        DDLogInfo("Info")
//        DDLogWarn("Warn")
//        DDLogError("Error")
        
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


        return true
    }
    
    func optInForPushNotifications(application: UIApplication) {
        UserDefaults.standard.set(Date(), forKey: AppDelegate.lastPushNotificationCheck)
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, error) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
        }
        
        //get application instance ID
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
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
            DDLogDebug("An error occured setting the audio session category: \(error)")
        }
    }

    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let str = deviceToken.map { String(format: "%02X", $0) }.joined()
//        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        // Print it to console
        DDLogDebug("APNs device token: \(str)")
        
        Messaging.messaging().setAPNSToken(deviceToken, type: MessagingAPNSTokenType.unknown)
        DDLogDebug("APNs device token: \(Messaging.messaging().apnsToken)")
        if let firebaseToken = Messaging.messaging().fcmToken {
            DDLogDebug("FCM token: \(firebaseToken)")

            if let apnsToken = Messaging.messaging().apnsToken {
                let apnsTokenString = apnsToken.map { String(format: "%02X", $0) }.joined()
                self.updatePushToken(fcmToken: firebaseToken,
                                     apnsToken: apnsTokenString,
                                     preferredLanguage: L10n.shared.preferredLanguage,
                                     userAgent: Device.userAgent(), userVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, userUuid: NSUUID().uuidString)
            }
        }
    }

    func updatePushToken(fcmToken: String,
                         apnsToken: String,
                         preferredLanguage: String,
                         userAgent: String,
                         userVersion: String,
                         userUuid: String) {
        let provider = MoyaProvider<FwbcApiService>()
        // deviceUniqueIdentifier: String, apnsToken: String, fcmToken: String, nonce:
        provider.request(.pushTokenUpdate(fcmToken: fcmToken,
                                          apnsToken: apnsToken,
                                          preferredLanguage: preferredLanguage,
                                          userAgent: userAgent, userVersion: userVersion, userUuid: userUuid)) { result in
                                            switch result {
                                            case let .success(moyaResponse):
                                                do {
                                                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                                                    let data = moyaResponse.data
                                                    //                    var parsedObject: BookResponse

                                                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                                                    DDLogDebug("json: \(json)")
                                                    if let jsonObject = json as? [String:Any] {
                                                        DDLogDebug("jsonObject: \(jsonObject)")
                                                    }
                                                }
                                                catch {
                                                    DDLogDebug("pushTokenUpdate error: \(error)")
                                                }

                                            case let .failure(error):
                                                DDLogDebug(".failure: \(error)")
                                                // this means there was a network failure - either the request
                                                // wasn't sent (connectivity), or no response was received (server
                                                // timed out).  If the server responds with a 4xx or 5xx error, that
                                                // will be sent as a ".success"-ful response.
                                                //                errorClosure(error)
                                                DDLogDebug(".failure")
                                            }
        }
    }

//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
//        DDLogDebug("response.actionIdentifier: \(response.actionIdentifier)")
//        //        Messaging.messaging().appDidReceiveMessage()
//    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        DDLogDebug("response \(response)")
        print("Handle push from background or closed")
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        print("\(response.notification.request.content.userInfo)")

        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            DDLogDebug("Message Closed")
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print ("App is Open")
        }
        
        // Else handle any custom actions. . .
        completionHandler()
    }
    
    // handle notifications while in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Handle push from foreground")
        print("\(notification.request.content.userInfo)")

        completionHandler(UNNotificationPresentationOptions.alert)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        // Print the error to console (you should alert the user that registration failed)
        DDLogDebug("APNs registration failed: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        switch application.applicationState {
            
        case .inactive:
            print("Inactive")
            //Show the view with the content of the push
            completionHandler(.newData)
            
        case .background:
            print("Background")
            //Refresh the local model
            completionHandler(.newData)
            
        case .active:
            print("Active")
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
        DDLogDebug("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogDebug("applicationDidEnterBackground")
        //        Messaging.messaging().shouldEstablishDirectChannel = false
        //        DDLogDebug("Disconnected from FCM.")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DDLogDebug("applicationDidEnterBackground")
        
        application.applicationIconBadgeNumber = 0

        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogDebug("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogDebug("applicationWillTerminate")

        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}



extension AppDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        DDLogDebug("Firebase didRefreshRegistrationToken token: \(fcmToken)")
        if let apnsToken = Messaging.messaging().apnsToken {
            let apnsTokenString = apnsToken.map { String(format: "%02X", $0) }.joined()
            self.updatePushToken(fcmToken: fcmToken,
                                 apnsToken: apnsTokenString,
                                 preferredLanguage: L10n.shared.preferredLanguage,
                                 userAgent: Device.userAgent(),
                                 userVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                                 // TODO: cache User.uuid in product or a session service
                                 userUuid: NSUUID().uuidString)
        }
    }

    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        DDLogDebug("messaging remoteMessage.appData: \(remoteMessage.appData)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        DDLogDebug("Firebase didRefreshRegistrationToken token: \(fcmToken)")

    }
    
    
}
