//
//  PushRegistryDelegate.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import PushKit
import UserNotifications

final class PushService: NSObject, PKPushRegistryDelegate {

  private var onReceivePush: (PushPayload, @escaping () -> Void) -> Void
  private var registry: PKPushRegistry
  
  struct PushPayload {
    var callId: UUID
    var callerId: String
    var callerName: String
  }
  
  enum RegisterError: Error {
    case unhandled
  }
  
  init(onReceivePush: @escaping (PushPayload, @escaping () -> Void) -> Void) {
    self.onReceivePush = onReceivePush
    self.registry = PKPushRegistry(queue: nil)
    super.init()
    self.registry.delegate = self
  }
  
  // Push通知用のクレデンシャルの生成を開始する
  func register() {
    registry.desiredPushTypes = [.voIP]
  }
  
  // Push通知用TokenのHex文字列を取得する
  // すでに以前にAPNsに登録済みの場合にStringが返る
  func getTokenHex() -> String? {
    if let token = self.registry.pushToken(for: .voIP) {
      return PushService.toHex(token: token)
    } else {
      return nil
    }
  }
  
  /*
   =========================
   PKPushRegistryDelegate
   =========================
   */
  
  // Push通知用クレデンシャルの更新に成功したとき
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    // ここでは何もしない
    // 適当なタイミングで pushService.getTokenHexによりトークンを取得している
  }
  
  // Push通知用クレデンシャルの更新に失敗したとき
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    // TODO
  }
  
  // remote notificationを受け取ったとき
  // PushPayloadから情報を抽出し、CallServiceに着信を知らせる
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    
    let callIdStr = payload.dictionaryPayload["call_id"] as! String
    let callId = UUID(uuidString: callIdStr)!
    let callerId = payload.dictionaryPayload["caller_id"] as! String
    let callerName = payload.dictionaryPayload["caller_name"] as! String
    let push = PushPayload(callId: callId, callerId: callerId, callerName: callerName)
    
    self.onReceivePush(push, completion)
  }
  
  /*
   ===================
   Static functions
   ===================
   */
  
  static private func toHex(token: Data) -> String {
    return token.map { String(format: "%02hhx", $0) }.joined()
  }
  
  // Push通知の承認をユーザーにリクエストする
  static func requestAuth(onComplete: @escaping (Bool, Error?) -> Void) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .badge, .sound], completionHandler: onComplete)
  }
  
  // 現在のPush通知の承認状況を取得する
  static func getAuthStatus(callback: @escaping (UNAuthorizationStatus) -> Void) {
    UNUserNotificationCenter.current()
      .getNotificationSettings { settings in
        callback(settings.authorizationStatus)
      }
  }
}
