//
//  ContentView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/18.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    var body: some View {
        VStack(alignment: .center) {
            SigninWithAppleButton(onSuccess: { cred in  })
                .frame(width: 170.0, height: 50.0)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
