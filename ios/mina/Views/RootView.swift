//
//  SwiftUIView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RootView: View {
  @EnvironmentObject var store: Store
  
  var body: some View {
    Group {
      if (store.me == nil) {
        OnboardingView().transition(.opacity)
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

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environmentObject(Store())
  }
}
