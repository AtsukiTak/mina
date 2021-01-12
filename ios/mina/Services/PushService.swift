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

final class PushService {
  
  enum RegisterError: Error {
    case unhandled
  }
  
  private var registry: PKPushRegistry
  var delegate: PushDelegate
  
  init(delegate: PushDelegate) {
    self.delegate = delegate
    self.registry = PKPushRegistry(queue: nil)
    self.registry.delegate = delegate
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
  
  static func toHex(token: Data) -> String {
    return token.map { String(format: "%02hhx", $0) }.joined()
  }
  
  // Push通知の承認をユーザーにリクエストする
  static func requestAuth(onComplete: @escaping (Bool, Error?) -> Void) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .badge, .sound], completionHandler: onComplete)
  }
  
  // 現在のPush通知の承認状況を取得する
  static func getAuthStatus(callback: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current()
      .getNotificationSettings { settings in
        callback(settings.authorizationStatus == .authorized)
      }
  }
}

final class PushDelegate: NSObject, PKPushRegistryDelegate {
  
  private let callService: CallService
  var onRegistered: (String) -> Void
  
  init(_ callService: CallService) {
    self.callService = callService
    self.onRegistered = { _ in }
    super.init()
  }
  
  // Push通知用クレデンシャルの更新に成功したとき
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    self.onRegistered(PushService.toHex(token: pushCredentials.token))
  }
  
  // Push通知用クレデンシャルの更新に失敗したとき
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    // TODO
  }
  
  // remote notificationを受け取ったとき
  // PushPayloadから情報を抽出し、CallServiceに着信を知らせる
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    
    let callId = UUID()
    let callerId = "424242"
    let callerName = "atsuki"
    self.callService.reportIncomingCall(callId: callId, callerId: callerId, callerName: callerName, completion: completion)
  }
}
