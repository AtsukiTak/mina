//
//  SwiftUIView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RootView: View {
  @EnvironmentObject var initialDataStore: InitialDataStore
  @EnvironmentObject var callStore: CallStore
  @EnvironmentObject var errorStore: ErrorStore
  
  // Storeの初期化が終わるまではLoadingViewを表示し、
  // 終わった後はInitializedViewを表示する
  var body: some View {
    Group {
      if callStore.peer != nil {
        // 通話状態の時
        VideoView()
      } else {
        /*
        通話状態じゃない時
        */
        switch (initialDataStore.pushAuthStatus, initialDataStore.store) {
        // Storeの初期化が終わるまではLoadingViewを表示する
        case (.loading, _), (_, .loading):
          LoadingView()
          
        // 必要なデータの読み込みが終わったとき
        case let (.loaded(auth), .loaded(store)):
          if store == nil {
            // ユーザー未登録のとき
            OnboardingView(onSignup: onSignup)
          }
          let store = store!
          
          // Push通知を許可しているかどうかによって分岐
          switch auth {
          case .notDetermined:
            RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
          case .authorized:
            FirstView()
              .environmentObject(store)
          case .denied, .provisional, .ephemeral:
            // TODO: PushNotificationDeniedView
            RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
          @unknown default:
            // TODO: PushNotificationDeniedView
            RequestPushNotification(onAuthed: { ok, err in onAuthed(ok, err, store) })
          }
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
      self.initialDataStore.updateStore(store)
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
      self.initialDataStore.updatePushAuthStatus(.authorized)
    } else {
      self.initialDataStore.updatePushAuthStatus(.denied)
    }
  }
  
  // Storeの初期化が終わるまで表示される画面
  struct LoadingView: View {
    var body: some View {
      Text("Loading...")
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
