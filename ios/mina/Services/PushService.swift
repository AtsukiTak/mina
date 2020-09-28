//
//  PushRegistryDelegate.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import PushKit

final class PushService {
    
    enum RegisterError: Error {
        case unhandled
    }
    
    private var registry: PKPushRegistry
    
    init(delegate: PushDelegate) {
        self.registry = PKPushRegistry(queue: nil)
        self.registry.delegate = delegate
    }

    // Push通知用のクレデンシャルの生成を開始する
    func register() {
        registry.desiredPushTypes = [.voIP]
    }
    
    
    
}

final class PushDelegate: NSObject, PKPushRegistryDelegate {
    
    private let callService: CallService
    
    init(callService: CallService) {
        self.callService = callService
        super.init()
    }
    
    // Push通知用クレデンシャルの更新に成功したとき
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // サーバーに通知する
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
