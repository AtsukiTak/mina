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
    private var delegate: PushServiceDelegate?
    private var registry: PKPushRegistry?
    
    private static let shared = PushService()

    // Push通知用のクレデンシャルの生成を開始する
    // NOTE
    // registerプロセスが完了する前に、新しいregisterプロセスを開始してしまうと、
    // 古いプロセスの結果を受け取ることができなくなる
    static func register(_ onCompleted: @escaping (Result<PKPushCredentials, Error>) -> Void) {
        let registry = PKPushRegistry(queue: nil)
        let delegate = PushServiceDelegate(onCompleted: onCompleted)
        registry.delegate = delegate
        registry.desiredPushTypes = [.voIP]
        
        shared.delegate = delegate
        shared.registry = registry
    }
}

final private class PushServiceDelegate: NSObject, PKPushRegistryDelegate {
    
    enum RegisterError: Error {
        case unhandled
    }
    
    private let onCompleted: (Result<PKPushCredentials, Error>) -> Void
    
    init(onCompleted: @escaping (Result<PKPushCredentials, Error>) -> Void) {
        self.onCompleted = onCompleted
        super.init()
    }
    
    // Push通知用クレデンシャルの更新に成功したとき
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        self.onCompleted(.success(pushCredentials))
    }
    
    // Push通知用クレデンシャルの更新に失敗したとき
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        self.onCompleted(.failure(RegisterError.unhandled))
    }
    
    // remote notificationを受け取ったとき
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        defer {
            completion()
        }
        
        // TODO
    }
}
