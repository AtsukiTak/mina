//
//  Store.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

class Store: ObservableObject {
  @Published var callMode: Bool
  @Published private(set) var relationships: [Relationship]
  @Published private(set) var receivedPartnerRequests: [PartnerRequest]
  private(set) var applePushToken: String?
  
  var me: Me
  var errorStore: ErrorStore
  
  // フルイニシャライザ
  // イニシャライザはデバッグ時などに使用する
  // 本番環境では `createWithInitialData` メソッドを使用する
  init(me: Me,
       relationships: [Relationship] = [],
       receivedPartnerRequests: [PartnerRequest] = [],
       errorStore: ErrorStore
  ) {
    self.callMode = false
    self.me = me
    self.relationships = relationships
    self.receivedPartnerRequests = receivedPartnerRequests
    self.applePushToken = nil
    self.errorStore = errorStore
  }
  
  func fetchMyData(callback: @escaping () -> Void) {
    self.errorStore.clear()
    
    ApiService.GraphqlApi().getMyData(me: me) { res in
      DispatchQueue.main.async {
        switch res {
        case .success(let output):
          self.applePushToken = output.applePushToken
          self.relationships = output.relationships
          self.receivedPartnerRequests = output.receivedPartnerRequests
        case .failure(let err):
          self.errorStore.set(err)
        }
        callback()
      }
    }
  }
  
  func updateApplePushToken() {
    if let token = AppDelegate.shared.pushService?.getTokenHex() {
      if token != self.applePushToken {
        ApiService.GraphqlApi().setApplePushToken(me: me, token: token) { _ in }
      }
    }
  }
  
  func sendPartnerRequest(toUserId: String, onComplete: @escaping (Result<(), Error>) -> Void) {
    self.errorStore.clear()
      
    ApiService.GraphqlApi().sendPartnerRequest(me:me, toUserId: toUserId) { res in
      switch res {
      case .success(()):
        onComplete(.success(()))
      case .failure(let err):
        self.errorStore.set(err)
        onComplete(.failure(err))
      }
    }
  }
  
  func acceptPartnerRequest(requestId: UUID, onComplete: @escaping () -> Void) {
    // 前提条件のチェック
    if !self.receivedPartnerRequests.contains(where: { $0.id == requestId }) {
      // エラーにしない
      onComplete()
      return;
    }
    
    // errorの初期化
    self.errorStore.clear()
    
    // APIリクエスト
    ApiService.GraphqlApi().acceptPartnerRequest(me: me, requestId: requestId) { res in
      DispatchQueue.main.async {
        switch res {
        case .success(_):
          self.receivedPartnerRequests.removeAll(where: { $0.id == requestId})
        case .failure(let err):
          self.errorStore.set(err)
        }
      }
      onComplete()
    }
  }
  
  func addCallSchedule(relationshipId: UUID, time: Time, weekdays: [Weekday], onComplete: @escaping () -> Void) {
    // 前提条件のチェック
    guard let relationship = self.relationships.first(where: { $0.id == relationshipId })
    else {
      self.errorStore.set("Relationship not found")
      onComplete()
      return;
    }
    
    // errorの初期化
    self.errorStore.clear()
    
    // APIリクエスト
    ApiService.GraphqlApi()
      .addCallSchedule(me: me,
                       relationship: relationship,
                       time: time,
                       weekdays: weekdays) { res in
        DispatchQueue.main.async {
          switch res {
          case .success(let newRelationship):
            let idx = self.relationships.firstIndex(where: { $0.id == relationship.id })!
            self.relationships[idx] = newRelationship
          case .failure(let err):
            self.errorStore.set(err)
          }
        }
        onComplete()
    }
  }
}
