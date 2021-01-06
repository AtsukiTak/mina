//
//  OnboardingView.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/05.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var store: Store
  
  @State var processing: Bool = false
  
  var body: some View {
    VStack {
      Text("Welcome to mina App!")
        .font(.largeTitle)
        .padding(.bottom, 50)
      
      Button(action: {
        processing = true
        store.signup()
      }, label: {
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
      return "Loading..."
    } else {
      return "Start"
    }
  }
}

struct OnboardingView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingView()
  }
}
