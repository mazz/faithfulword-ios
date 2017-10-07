import UIKit
import IQKeyboardManagerSwift
import AVFoundation
import Firebase
import Moya
import UserNotifications
import L10n_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.sharedManager().enable = true
        UNUserNotificationCenter.current().delegate = self
    
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
//        Messaging.messaging().shouldEstablishDirectChannel = true
        
        return true
    }

    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let str = deviceToken.map { String(format: "%02hhx", $0) }.joined()
//        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        // Print it to console
        print("APNs device token: \(str)")
        
        Messaging.messaging().setAPNSToken(deviceToken, type: MessagingAPNSTokenType.unknown)
        print("APNs device token: \(Messaging.messaging().apnsToken)")
        if let firebaseToken = Messaging.messaging().fcmToken {
            print("FCM token: \(firebaseToken)")

            if let apnsToken = Messaging.messaging().apnsToken {
                let apnsTokenString = apnsToken.map { String(format: "%02hhx", $0) }.joined()
                self.updatePushToken(fcmToken: firebaseToken, apnsToken: apnsTokenString, preferredLanguage: L10n.shared.preferredLanguage)
            }
//            guard let apnsToken = Messaging.messaging().apnsToken,
//            guard let apnsTokenString = apnsToken.reduce("", {$0 + String(format: "%02X", $1)}) {
//
//            } else {
//
//            }
            
//            if let apnsToken = Messaging.messaging().apnsToken,
//            if let apnsTokenString = apnsToken.reduce("", {$0 + String(format: "%02X", $1)}) {
//                self.updatePushToken(fcmToken: firebaseToken, apnsToken: apnsTokenString, preferredLanguage: L10n.shared.preferredLanguage)
//            }
            
            //            self.updatePushToken(fcmToken: firebaseToken)
        }
    }

    func updatePushToken(fcmToken: String, apnsToken: String, preferredLanguage: String) {
        let provider = MoyaProvider<KJVRVGService>()
        // deviceUniqueIdentifier: String, apnsToken: String, fcmToken: String, nonce:
        provider.request(.pushTokenUpdate(fcmToken: fcmToken, apnsToken: apnsToken, preferredLanguage: preferredLanguage)) { result in
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    //                    var parsedObject: BookResponse
     
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    print("json: \(json)")
                    if let jsonObject = json as? [String:Any] {
                        print("jsonObject: \(jsonObject)")
                    }
                }
                catch {
                    print("error: \(error)")
                }
     
            case let .failure(error):
                print(".failure: \(error)")
                // this means there was a network failure - either the request
                // wasn't sent (connectivity), or no response was received (server
                // timed out).  If the server responds with a 4xx or 5xx error, that
                // will be sent as a ".success"-ful response.
                //                errorClosure(error)
                print(".failure")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }
    
    
    // Push notification received
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
        // Print notification payload data
        print("Push notification received: \(data)")
        Messaging.messaging().appDidReceiveMessage(data)
        
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
        print("Disconnected from FCM.")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0

        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase didRefreshRegistrationToken token: \(fcmToken)")
        if let apnsToken = Messaging.messaging().apnsToken {
            let apnsTokenString = apnsToken.map { String(format: "%02hhx", $0) }.joined()
            self.updatePushToken(fcmToken: fcmToken, apnsToken: apnsTokenString, preferredLanguage: L10n.shared.preferredLanguage)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("messaging remoteMessage.appData: \(remoteMessage.appData)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
}
