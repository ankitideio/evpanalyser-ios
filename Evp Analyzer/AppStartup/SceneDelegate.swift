//
//  SceneDelegate.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 04/06/2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
//        guard let windowScence = (scene as? UIWindowScene) else { return }
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.window = self.window
//        self.window = UIWindow(windowScene: windowScence)
//        self.initializeTabBar()
        if UserDefaults.standard.bool(forKey: "session") == true{
            
            initializeTabBar()
        }else{
            initializeSplash()
           
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("Disconnect")
        UserDefaults.standard.set(false, forKey: "session")
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
         print("Become active")

        if UserDefaults.standard.bool(forKey: "session") == true{
            
            initializeTabBar()
        }else{
            initializeSplash()
           
        }
        
//        }
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("Resign")
        UserDefaults.standard.set(true, forKey: "session")
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Forground")
        
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Background")
        UserDefaults.standard.set(true, forKey: "session")
        window?.rootViewController = nil
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
     

    func initializeTabBar() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let tabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
//        self.window?.rootViewController = tabBarController
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let redViewController = mainStoryBoard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
        let nav = UINavigationController.init(rootViewController: redViewController)
        nav.isNavigationBarHidden = true
        UIApplication.shared.windows.first?.rootViewController = nav
    }
    func initializeSplash(){
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let redViewController = mainStoryBoard.instantiateViewController(withIdentifier: "SplashVideoVC") as! SplashVideoVC
        let nav = UINavigationController.init(rootViewController: redViewController)
        nav.isNavigationBarHidden = true
        UIApplication.shared.windows.first?.rootViewController = nav
    }
}

