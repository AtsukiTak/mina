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
    
    private var _userCred: Credential? = nil // インスタンス生成からアプリケーションの起動完了までの間だけnil
    
    var userCred: Credential {
        return self._userCred! // 値がセットされているはず
    }
    
    var pushService: PushService? = nil
    
    static func shared() -> AppDelegate {
        UIApplication.shared.delegate! as! AppDelegate
    }

    // アプリケーションの起動後に呼ばれる
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            self._userCred = try self.getCredential()
            self.pushService = PushService(self.userCred)
            return true
        } catch {
            return false
        }
    }
    
    // クレデンシャルを取得、または生成する
    func getCredential() throws -> Credential {
        if let cred = try KeychainService().readCred(){
            return cred
        } else {
            // TODO
            // クレデンシャルを適切に生成する
            let cred = Credential(username: "", password: "")
            try KeychainService().saveCred(cred: cred)
            return cred
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
