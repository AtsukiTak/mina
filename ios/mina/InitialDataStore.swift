//
//  InitialDataStore.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/16.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation
import SwiftUI

class InitialDataStore: ObservableObject {
  @Published var pushAuthStatus: Load<UNAuthorizationStatus> = .loading
  @Published var store: Load<Store?> = .loading
  let errorStore: ErrorStore
  
  enum Load<T> {
    case loading
    case loaded(T)
  }
  
  init(errorStore: ErrorStore) {
    self.errorStore = errorStore
  }
  
  func load() {
    // PushAuthStatusの取得
    PushService.getAuthStatus(callback: { authStatus in
      self.updatePushAuthStatus(authStatus)
    })
    
    // Meの取得
    let maybeMe = try! KeychainService().readMe()
    guard let me = maybeMe else {
      self.store = .loaded(nil)
      return;
    }
    
    // Storeの初期化
    let store = Store(me: me, errorStore: errorStore)
    store.fetchMyData() {
      store.updateApplePushToken()
      self.updateStore(store)
    }
  }
  
  func updateStore(_ store: Store) {
    DispatchQueue.main.async {
      self.store = .loaded(store)
    }
  }
  
  func updatePushAuthStatus(_ auth: UNAuthorizationStatus) {
    DispatchQueue.main.async {
      self.pushAuthStatus = .loaded(auth)
    }
  }
}
