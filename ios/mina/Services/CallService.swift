//
//  CallService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/26.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import CallKit

final class CallService: NSObject {
    
    private let provider: CXProvider
    private let delegate: CallDelegate
    
    init(delegate: CallDelegate) {
        let config = CXProviderConfiguration(localizedName: "mina")
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        config.supportsVideo = true
        config.supportedHandleTypes = [.generic] // 独自のIDで相手を特定する
        
        self.provider = CXProvider(configuration: config)
        
        self.delegate = delegate
        
        super.init()
        
        self.provider.setDelegate(delegate, queue: nil)
    }
    
    func reportIncomingCall(callId: UUID,
                            callerId: String,
                            callerName: String,
                            completion: @escaping () -> Void) {
        // 着信に関する情報をもつオブジェクトの生成
        let update = CXCallUpdate()
        update.localizedCallerName = callerName
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.hasVideo = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        update.supportsDTMF = false
        
        self.provider.reportNewIncomingCall(with: callId, update: update) { err in
            if let err = err {
                print(err)
                completion()
            } else {
                // systemが着信を許可したので通話プロセスを開始する
                CallManager.shared.start()
            }
        }
    }
}

final class CallDelegate: NSObject, CXProviderDelegate {
    
    override init() {
        super.init()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("reset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("fulfil")
    }
}
