//
//  RequestPushNotification.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/12.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RequestPushNotification: View {
  @EnvironmentObject var store: Store
  
  var body: some View {
    VStack {
      Text("mina では指定された時間に電話をかけるためにPush通知を利用しています。アプリの利用を開始する前にPush通知を許可してください。")
        .font(.body)
        .padding()
      
      Button(action: {
        store.requestPushNotificationAuth()
      }, label: {
        Card(bgColor: .main) {
          Text("許可する")
            .foregroundColor(.white)
        }
      })
      .disabled(store.isPushAuthorized == .loading)
    }
  }
}

struct RequestPushNotification_Previews: PreviewProvider {
  static var previews: some View {
    RequestPushNotification()
      .environmentObject(Store())
  }
}
