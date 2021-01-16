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
  
  let errorStore: ErrorStore
  let callStore: CallStore
  
  let callService: CallService
  let pushService: PushService
  
  override init() {
    self.errorStore = ErrorStore()
    self.callStore = CallStore(errorStore: errorStore)
    
    self.callService = CallService()
    self.pushService = PushService()
    
    super.init()
  }
  
  class var shared: AppDelegate {
    return UIApplication.shared.delegate! as! AppDelegate
  }
  
  // アプリケーションの起動後に呼ばれる
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    self.pushService.onReceivePush { [weak self] push, completion in
      self!.callService.reportIncomingCall(callId: push.callId,
                                     callerId: push.callerId,
                                     callerName: push.callerName) { err in
        if let err = err {
          self!.errorStore.set(err)
        }
        completion() // push通知の処理の完了通知
      }
      self!.callStore.startCallProcess()
    }
    pushService.register()

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
