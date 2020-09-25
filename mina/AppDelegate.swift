//
//  AppDelegate.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/18.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import UIKit
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var user: User? = nil
    var callService: CallService?
    var pushService: PushService?
    
    class var share: AppDelegate {
        return UIApplication.shared.delegate! as! AppDelegate
    }

    // アプリケーションの起動後に呼ばれる
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("launched!!")
        
        let callService = CallService()
        let pushService = PushService(callService: callService)
        pushService.register()
        
        self.callService = callService
        self.pushService = pushService
        
        do {
            self.user = try UserRepository.findUser()
            return true
        } catch {
            return false
        }
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
