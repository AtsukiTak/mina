//
//  SwiftUIView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RootView: View {
  @ObservedObject private var storeInitializer: StoreInitializer
  
  init() {
    self.storeInitializer = StoreInitializer()
  }
  
  var body: some View {
    switch storeInitializer.store {
    case .uninitialized:
      OnboardingView()
    case .initialized(let store):
      InitializedView()
        .environmentObject(store)
    }
  }
  
  // Storeの初期化を管理するクラス
  // 当初、RootViewに、 @State var store: Store? のようなStateを持たせようとしたが、
  // Stateをbody関数外で更新するのは問題がある（コンパイルもできなかった）ので
  // ObservableObjectなクラスを導入した。
  class StoreInitializer: ObservableObject {
    @Published var store: Initializing<Store>
    
    enum Initializing<T> {
      case uninitialized
      case initialized(T)
    }
    
    init() {
      self.store = .uninitialized
      
      Store.createWithInitialData { store in
        DispatchQueue.main.async {
          self.store = .initialized(store)
        }
      }
    }
  }
  
  // Storeの初期化が終わった後に表示されるView
  struct InitializedView: View {
    @EnvironmentObject var store: Store
    
    var body: some View {
      Group {
        if (store.isPushAuthorized != .loaded(true)) {
          RequestPushNotification().transition(.opacity)
        } else if (store.callMode) {
          VideoView().transition(.opacity)
        } else {
          FirstView().transition(.opacity)
        }
      }.alert(item: $store.error) { err in
        Alert(title: Text("Unexpected Error"), message: Text(err.desc))
      }
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
