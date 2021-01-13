//
//  SwiftUIView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RootView: View {
  @ObservedObject private var loader: InitDataLoader = InitDataLoader()
  @ObservedObject private var errorStore: ErrorStore = ErrorStore()
  
  init() {
    self.loader.load(errorStore: errorStore)
  }
  
  // Storeの初期化が終わるまではLoadingViewを表示し、
  // 終わった後はInitializedViewを表示する
  var body: some View {
    Group {
      switch (loader.pushAuthStatus, loader.store) {
      case (.loading, _), (_, .loading):
        LoadingView()
      case let (.loaded(auth), .loaded(store)):
        if store == nil {
          // ユーザー未登録
          OnboardingView(onSignup: onSignup)
        }
        let store = store!
        
        switch auth {
        case .notDetermined:
          RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
        case .authorized:
          InitializedView()
            .environmentObject(store)
            .environmentObject(errorStore)
        case .denied, .provisional, .ephemeral:
          // TODO: PushNotificationDeniedView
          RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
        @unknown default:
          // TODO: PushNotificationDeniedView
          RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
        }
      }
    }.alert(item: $errorStore.err) { err in
      Alert(title: Text("Unexpected Error"), message: Text(err.desc))
    }
  }
  
  func onSignup(res: Result<Me, Error>) {
    switch res {
    case .success(let me):
      // いま新規登録したばかりなのでGetMeをする必要はない
      let store = Store(me: me, errorStore: errorStore)
      self.loader.updateStore(store)
    case .failure(let err):
      self.errorStore.set(err)
    }
  }
  
  // Push通知の承認が得られた時/得られなかった時
  func onAuthed(_ ok: Bool, _ err: Error?, _ store: Store) {
    if let err = err {
      self.errorStore.set(err)
      return;
    }
    if ok {
      store.updateApplePushToken()
      self.loader.updatePushAuthStatus(.authorized)
    } else {
      self.loader.updatePushAuthStatus(.denied)
    }
  }
  
  class InitDataLoader: ObservableObject {
    @Published var pushAuthStatus: Load<UNAuthorizationStatus> = .loading
    @Published var store: Load<Store?> = .loading
    
    enum Load<T> {
      case loading
      case loaded(T)
    }
    
    func load(errorStore: ErrorStore) {
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
  
  // Storeの初期化が終わるまで表示される画面
  struct LoadingView: View {
    var body: some View {
      Text("Loading...")
    }
  }
  
  // Storeの初期化が終わった後に表示されるView
  struct InitializedView: View {
    @EnvironmentObject var store: Store
    
    var body: some View {
      Group {
        if (store.callMode) {
          VideoView().transition(.opacity)
        } else {
          FirstView().transition(.opacity)
        }
      }
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
