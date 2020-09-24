//
//  PushRegistryDelegate.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import PushKit

class PushService: NSObject, PKPushRegistryDelegate {
    var userCred: Credential
    var pushRegistry: PKPushRegistry
    
    init(_ userCred: Credential) {
        self.userCred = userCred
        self.pushRegistry = PKPushRegistry(queue: nil)
        super.init()
        
        // pushRegistry.delegateはweak propertyなので循環参照にならない
        self.pushRegistry.delegate = self
        
        // ↓の値をassignしたタイミングで登録プロセスが開始される
        self.pushRegistry.desiredPushTypes = [.voIP]
    }
    
    // Push通知用クレデンシャルの更新に成功したとき
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // TODO
        // サーバーに通知する
    }
    
    // Push通知用クレデンシャルの更新に失敗したとき
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        // とりあえず何もしない
    }
}
