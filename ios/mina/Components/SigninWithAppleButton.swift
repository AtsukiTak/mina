//
//  SigninWithAppleButton.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/18.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI
import AuthenticationServices

final class SigninWithAppleButton: NSObject {
    let onSuccess: (ASAuthorizationAppleIDCredential) -> Void

    init(onSuccess: @escaping (ASAuthorizationAppleIDCredential) -> Void) {
        self.onSuccess = onSuccess
        super.init()
    }
}

// ASAuthorizationAppleIDButtonを表示
extension SigninWithAppleButton: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: .signUp, style: .black)
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.addTarget(self,
                         action: #selector(handleButtonPress),
                         for: .touchUpInside)
    }
}

// ボタンが押された時の挙動
extension SigninWithAppleButton {
    @objc
    func handleButtonPress() {
        GlobalEnvironment.shared.callMode = true
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension SigninWithAppleButton: ASAuthorizationControllerDelegate {
    // 成功時
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let cred = authorization.credential as? ASAuthorizationAppleIDCredential {
            // callbackを呼び出す
            self.onSuccess(cred)
        }
    }
}

// signupモーダル表示時の背景ウインドウを指定する（たぶん）
// とりあえずシングルディスプレイアプリを想定しているので
// 最初のwindowを返してる
extension SigninWithAppleButton: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.windows[0]
    }
}

struct SigninWithAppleButton_Previews: PreviewProvider {
    static var previews: some View {
        SigninWithAppleButton(onSuccess: { cred in
        })
            .frame(width: 150.0, height: 30)
    }
}
