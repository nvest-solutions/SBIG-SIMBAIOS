//
//  AppDelegate.swift
//  SBIG Simba
//
//  Created by Apple on 25/01/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate ,UNUserNotificationCenterDelegate,UIDocumentInteractionControllerDelegate{

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
       
        return true
    }
    
    // Handle notification when the app is in the foreground
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .sound, .badge])
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let filePath = response.notification.request.content.userInfo["filePath"] as? String {
            let url = URL(fileURLWithPath: filePath)
            DispatchQueue.main.async {
                       if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
                         
                           let documentInteractionController = UIDocumentInteractionController(url: url)
                           documentInteractionController.delegate = self
                           documentInteractionController.presentOptionsMenu(from: topViewController.view.bounds, in: topViewController.view, animated: true)
                       }
                   }
            
        }
        completionHandler()
    }

}

