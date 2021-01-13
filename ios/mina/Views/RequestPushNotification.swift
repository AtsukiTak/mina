//
//  RequestPushNotification.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/12.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import SwiftUI

// この画面が表示されるのは、UNAuthorizationStatusがnotDeterminedのときのみ
struct RequestPushNotification: View {
  var onAuthed: (Bool, Error?) -> Void
  
  var body: some View {
    VStack {
      Text("mina では指定された時間に電話をかけるためにPush通知を利用しています。アプリの利用を開始する前にPush通知を許可してください。")
        .font(.body)
        .padding()
      
      Button(action: requestAuth, label: {
        Card(bgColor: .main) {
          Text("許可する")
            .foregroundColor(.white)
        }
      })
    }
  }
  
  func requestAuth() {
    PushService.requestAuth(onComplete: onAuthed)
  }
}

struct RequestPushNotification_Previews: PreviewProvider {
  static var previews: some View {
    RequestPushNotification(onAuthed: { _, _ in })
  }
}
