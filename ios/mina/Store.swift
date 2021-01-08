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
  @Published private(set) var me: Me?
  @Published private(set) var relationships: [Relationship]
  @Published private(set) var receivedPartnerRequests: [PartnerRequest]
  @Published var error: ErrorRepr?
  
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
  
  // シンプルイニシャライザ
  // イニシャライザはデバッグ時などに使用する
  // 本番環境では `createWithInitialData` メソッドを使用する
  convenience init() {
    self.init(me: nil, relationships: [], receivedPartnerRequests: [])
  }
  
  // フルイニシャライザ
  // イニシャライザはデバッグ時などに使用する
  // 本番環境では `createWithInitialData` メソッドを使用する
  init(me: Me?, relationships: [Relationship], receivedPartnerRequests: [PartnerRequest]) {
    self.callMode = false
    self.me = me
    self.relationships = relationships
    self.receivedPartnerRequests = receivedPartnerRequests
    self.error = nil
  }
  
  // 初期データと共にStoreを生成する
  static func createWithInitialData() -> Store {
    let store = Store()
    
    do {
      store.me = try KeychainService().readMe()
    } catch {
      store.error = ErrorRepr(error)
      return store;
    }
    
    if let me = store.me {
      ApiService.GraphqlApi().getMyData(me: me) { res in
        switch res {
        case .success(let output):
          store.error = nil
          store.relationships = output.relationships
          store.receivedPartnerRequests = output.receivedPartnerRequests
        case .failure(let err):
          store.error = ErrorRepr(err)
        }
      }
    }
    
    return store
  }
  
  // ユーザー登録を行うユースケース
  // - `signupAsAnonymous` APIを呼び出す
  // - 結果をKeyChainに保存する
  // - Store.meを更新する（他の値はそのまま）
  func signup() {
    if (self.me != nil) {
      self.error = ErrorRepr("Already registered")
      return;
    }
    
    ApiService.GraphqlApi().signupAsAnonymous(callback: { res in
      do {
        let me = try res.get()
        try KeychainService().saveMe(me: me)
        DispatchQueue.main.async { [weak self] in
          self?.me = me
        }
      } catch {
        DispatchQueue.main.async { [weak self] in
          self?.error = ErrorRepr(error)
        }
      }
    })
  }
  
  func sendPartnerRequest(toUserId: String, onComplete: @escaping (Result<(), Error>) -> Void) {
    guard let me = self.me else {
      self.error = ErrorRepr("not logged in")
      return;
    }
    
    self.error = nil
      
    ApiService.GraphqlApi().sendPartnerRequest(me:me, toUserId: toUserId) { res in
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
    guard let me = self.me else {
      self.error = ErrorRepr("not logged in")
      return;
    }
    
    // errorの初期化
    self.error = nil
    
    // APIリクエスト
    ApiService.GraphqlApi().acceptPartnerRequest(me: me, requestId: requestId) { res in
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
    guard let me = self.me else {
      self.error = ErrorRepr("not signed in")
      return;
    }
    
    // errorの初期化
    self.error = nil
    
    // APIリクエスト
    ApiService.GraphqlApi()
      .addCallSchedule(me: me,
                      relationship: relationship,
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
}
