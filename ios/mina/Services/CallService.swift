//
//  CallService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/26.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import CallKit

final class CallService: NSObject, CXProviderDelegate {
  
  // CXProviderはGlobalに1つだけ存在させるべき（らしい）
  // ので、CallServiceもGlobalに1つだけ存在させる
  private let provider: CXProvider
  
  override init() {
    let config = CXProviderConfiguration(localizedName: "mina")
    config.maximumCallGroups = 1
    config.maximumCallsPerCallGroup = 1
    config.supportsVideo = true
    config.supportedHandleTypes = [.generic] // 独自のIDで相手を特定する
    
    self.provider = CXProvider(configuration: config)
    
    super.init()
    
    self.provider.setDelegate(self, queue: nil)
  }
  
  func reportIncomingCall(callId: UUID,
                          callerId: String,
                          callerName: String,
                          completion: @escaping (Error?) -> Void) {
    // 着信に関する情報をもつオブジェクトの生成
    let update = CXCallUpdate()
    update.localizedCallerName = callerName
    update.remoteHandle = CXHandle(type: .generic, value: callerId)
    update.hasVideo = true
    update.supportsGrouping = false
    update.supportsUngrouping = false
    update.supportsHolding = false
    update.supportsDTMF = false
    
    self.provider.reportNewIncomingCall(with: callId, update: update, completion: completion)
  }
  
  /*
   ==================
   CXProviderDelegate
   ==================
   */
  func providerDidReset(_ provider: CXProvider) {
    print("reset")
  }
  
  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    print("fulfil")
  }
}
