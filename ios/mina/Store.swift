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
  private(set) var applePushToken: String?
  
  // Push通知が承認されているか
  @Published private(set) var isPushAuthorized: Loadable<Bool>
  
  // すべてのUnexpectedなエラー
  @Published var error: ErrorRepr?
  
  enum Loadable<T: Equatable>: Equatable {
    case loading
    case loaded(T)
  }
  
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
  init(me: Me?,
       relationships: [Relationship],
       receivedPartnerRequests: [PartnerRequest],
       isPushAuthorized: Loadable<Bool> = .loading
  ) {
    self.callMode = false
    self.me = me
    self.relationships = relationships
    self.receivedPartnerRequests = receivedPartnerRequests
    self.applePushToken = nil
    self.isPushAuthorized = isPushAuthorized
    self.error = nil
  }
  
  // 初期データと共にStoreを生成する
  static func createWithInitialData(callback: @escaping (Store) -> Void) {
    // Push通知の承認状態を取得する
    func getPushAuthStatus(_ store: Store, callback: @escaping (Store) -> Void) {
      PushService.getAuthStatus(callback: { authed in
        DispatchQueue.main.async {
          store.isPushAuthorized = .loaded(authed)
          callback(store)
        }
      })
    }
    
    // API経由でユーザーデータを取得する
    func getMyData(_ store: Store, callback: @escaping (Store) -> Void) {
      if let me = store.me {
        ApiService.GraphqlApi().getMyData(me: me) { res in
          DispatchQueue.main.async {
            switch res {
            case .success(let output):
              store.error = nil
              store.applePushToken = output.applePushToken
              store.relationships = output.relationships
              store.receivedPartnerRequests = output.receivedPartnerRequests
              // 念のため、毎回pushTokenの確認を行う
              store.updateApplePushToken()
            case .failure(let err):
              store.error = ErrorRepr(err)
            }
            callback(store)
          }
        }
      }
    }
    
    let store = Store()
    
    do {
      store.me = try KeychainService().readMe()
    } catch {
      store.error = ErrorRepr(error)
      return callback(store);
    }
    
    getMyData(store) {
      getPushAuthStatus($0) {
        callback($0)
      }
    }
  }
  
  // Push通知を送る承認をもらう
  func requestPushNotificationAuth() {
    self.isPushAuthorized = .loading
    
    PushService.requestAuth(onComplete: { authed, error in
      DispatchQueue.main.async {
        if let error = error {
          self.error = ErrorRepr(error)
          return;
        }
      
        self.isPushAuthorized = .loaded(authed)
      }
    })
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
        DispatchQueue.main.async {
          self.me = me
        }
      } catch {
        DispatchQueue.main.async {
          self.error = ErrorRepr(error)
        }
      }
    })
  }
  
  func updateApplePushToken() {
    guard let me = self.me else { return; }
    
    if let token = AppDelegate.shared.pushService?.getTokenHex() {
      if token != self.applePushToken {
        ApiService.GraphqlApi().setApplePushToken(me: me, token: token) { _ in }
      }
    }
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
        DispatchQueue.main.async {
          self.error = ErrorRepr(err)
        }
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
      DispatchQueue.main.async {
        switch res {
        case .success(_):
          self.receivedPartnerRequests.removeAll(where: { $0.id == requestId})
        case .failure(let err):
          self.error = ErrorRepr(err)
        }
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
        DispatchQueue.main.async {
          switch res {
          case .success(let newRelationship):
            let idx = self.relationships.firstIndex(where: { $0.id == relationship.id })!
            self.relationships[idx] = newRelationship
          case .failure(let err):
            self.error = ErrorRepr(err)
          }
        }
        onComplete()
    }
  }
}
