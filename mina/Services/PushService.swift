//
//  PushRegistryDelegate.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import PushKit
import Combine

final class PushService {
    // Push通知用のクレデンシャルの生成を開始する
    static func register() -> Future<PKPushCredentials, Error> {
        return Future { promise in
            
            let registry = PKPushRegistry(queue: nil)
            
            let delegate = PushServiceDelegate(promise: promise)
            registry.delegate = delegate
            
            // ↓の値をassignしたタイミングで登録プロセスが開始される
            registry.desiredPushTypes = [.voIP]
        }
    }
}

final private class PushServiceDelegate: NSObject, PKPushRegistryDelegate {
    
    enum RegisterError: Error {
        case unhandled
    }
    
    private var promise: Future<PKPushCredentials, Error>.Promise
    
    init(promise: @escaping Future<PKPushCredentials, Error>.Promise) {
        self.promise = promise
        super.init()
    }
    
    // Push通知用クレデンシャルの更新に成功したとき
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        self.promise(Result.success(pushCredentials))
    }
    
    // Push通知用クレデンシャルの更新に失敗したとき
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        self.promise(.failure(RegisterError.unhandled))
    }
}
