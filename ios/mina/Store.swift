//
//  Store.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

class Store: ObservableObject {
  @Published var callMode: Bool = false
  @Published var me: Me? = nil
  @Published var relationships: [Relationship] = []
  @Published var receivedPartnerRequests: [PartnerRequest] = []
  @Published var error: ErrorRepr? = nil
  
  // alertのトリガーにするためには、それがIdentifiableに準拠している必要がある。
  // 単純なStringはIdentifiableに準拠していないので新しくErrorRepr構造体を作る。
  // ReprはRepresentationの略。
  // また、エラーの文字列が同一でも別のエラーである可能性があるため、idはUUIDにしている
  struct ErrorRepr: Identifiable {
    var id: UUID
    var desc: String
    
    init(_ err: Error) {
      self.init(err.localizedDescription)
    }
    
    init(_ desc: String) {
      self.id = UUID()
      self.desc = desc
    }
  }
  
  init() {}
  
  func queryInitial(complete: @escaping () -> Void) {
    self.error = nil
    
    do {
      self.me = try KeychainService().readMe()
    } catch {
      self.error = ErrorRepr(error)
      return;
    }
    
    getPrivateApi()?.getMe { res in
      switch res {
      case .success(let output):
        self.error = nil
        self.relationships = output.relationships
        self.receivedPartnerRequests = output.receivedPartnerRequests
      case .failure(let err):
        self.error = ErrorRepr(err)
      }
      complete()
    }
  }
  
  func sendPartnerRequest(toUserId: String, onComplete: @escaping (Result<(), Error>) -> Void) {
    self.error = nil
    
    getPrivateApi()?.sendPartnerRequest(toUserId: toUserId) { res in
      switch res {
      case .success(()):
        onComplete(.success(()))
      case .failure(let err):
        self.error = ErrorRepr(err)
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
    self.error = nil
    
    // APIリクエスト
    getPrivateApi()?.acceptPartnerRequest(requestId: requestId) { res in
      switch res {
      case .success(_):
        self.receivedPartnerRequests.removeAll(where: { $0.id == requestId})
      case .failure(let err):
        self.error = ErrorRepr(err)
      }
      onComplete()
    }
  }
  
  func addCallSchedule(relationshipId: UUID, time: Time, weekdays: [Weekday], onComplete: @escaping () -> Void) {
    // 前提条件のチェック
    guard let relationship = self.relationships.first(where: { $0.id == relationshipId })
    else {
      self.error = ErrorRepr("Relationship not found")
      onComplete()
      return;
    }
    
    // errorの初期化
    self.error = nil
    
    // APIリクエスト
    getPrivateApi()?.addCallSchedule(relationship: relationship,
                               time: time,
                               weekdays: weekdays) { res in
      switch res {
      case .success(let newRelationship):
        let idx = self.relationships.firstIndex(where: { $0.id == relationship.id })!
        self.relationships[idx] = newRelationship
      case .failure(let err):
        self.error = ErrorRepr(err)
      }
      onComplete()
    }
  }
  
  /*
   ================
   private methods
   ================
   */
  private func getPrivateApi() -> ApiService.PrivateApi? {
    guard let me = self.me else {
      self.error = ErrorRepr("Not Logged In")
      return nil
    }
    return ApiService.PrivateApi(me: me)
  }
}
