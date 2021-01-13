//
//  OnboardingView.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/05.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
  @State var processing: Bool = false
  private let onSignup: (Result<Me, Error>) -> Void
  
  init(onSignup: @escaping (Result<Me, Error>) -> Void) {
    self.onSignup = onSignup
  }
  
  var body: some View {
    VStack {
      Text("Welcome to mina App!")
        .font(.largeTitle)
        .padding(.bottom, 50)
      
      Button(action: signup, label: {
        Card(bgColor: .main) {
          Text(buttonText)
            .foregroundColor(.white)
            .font(.title)
        }
      })
        .disabled(processing)
    }
  }
  
  var buttonText: String {
    if processing {
      return "Starting.."
    } else {
      return "Start"
    }
  }
  
  func signup() {
    processing = true
    ApiService.GraphqlApi().signupAsAnonymous(callback: { res in
      defer { processing = false }
      
      do {
        let me = try res.get()
        try KeychainService().saveMe(me: me)
        self.onSignup(.success(me))
      } catch {
        self.onSignup(.failure(error))
      }
    })
  }
}

struct OnboardingView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingView(onSignup: { _ in })
  }
}
