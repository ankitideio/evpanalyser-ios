//
//  AppDelegate.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 04/06/2022.
//

import UIKit
import GoogleMobileAds

//@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var clickCount : Int = 0

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UserDefaults.standard.set(false, forKey: "session")
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


extension AppDelegate{
    func updateClickCount(){
        self.clickCount += 1
        if self.clickCount == 3 {
            self.clickCount = 0
            let decoded = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKey.inAppPurchasekey)
            if !decoded {
                NotificationCenter.default.post(name: Notification.Name("showInterStitialAd"), object: nil, userInfo: nil)
            }
        }
    }
}

public extension UIApplication {
    
    public static func presentView(_ view: UIViewController) {
        if (view.isBeingPresented) {
            return
        }
        
        let window = UIApplication.shared.keyWindow!
         
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(view, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(view, animated: true, completion: nil)
        }
    }
}
