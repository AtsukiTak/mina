//
//  PartnerSearchView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/18.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

// パートナー検索画面
struct PartnerSearchView: View {
  @State private var input: String = ""
  @State var foundUserId: String? = nil
  
  @EnvironmentObject var store: Store
  
  init(foundUserId: String? = nil) {
    self.foundUserId = foundUserId // for preview
    // NavigationBarの設定
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = .main
    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().barStyle = .black
    UINavigationBar.appearance().tintColor = UIColor.white
  }
  
  var body: some View {
    VStack {
      // 基本この画面が描画されるときはmeが設定されているはずだが、
      // 評価のタイミングが分からないのでとりあえずifで囲っている
      if let me = store.me {
        // ユーザー検索が終わったら表示させない
        if foundUserId == nil {
          MyInfoSection(me: me)
            .padding(.bottom, 30)
          Divider()
            .padding(.bottom, 30)
        }
      }
      
      TextField("Input partner's ID", text: $input,
                onEditingChanged: { _ in },
                onCommit: { self.searchPartner() }
      )
      .padding(.bottom, 20)
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .transition(.slide)
      
      Spacer()
      
      if let userId = self.foundUserId {
        Divider()
        Spacer()
        FoundUserSection(userId: userId)
          .transition(.opacity)
        Spacer()
      }
    }
    .padding()
    .animation(.easeInOut)
    .navigationBarTitle("Search partner")
  }
  
  func searchPartner() {
    ApiService.GraphqlApi().searchPartner(userId: self.input) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let user):
          self.foundUserId = user.id
        case .failure(let error):
          self.store.error = Store.ErrorRepr(error)
        }
      }
    }
  }
  
  struct MyInfoSection: View {
    var me: Me
    
    var body: some View {
      VStack {
        HStack {
          Text("Your ID")
            .font(.headline)
          Spacer()
        }
        .padding(.bottom, 10)
        
        HStack {
          Image(systemName: "person.crop.circle")
              .imageScale(.large)
              .foregroundColor(.main)
          Text(me.id)
            .font(.headline)
            .foregroundColor(.main)
          Spacer()
        }
      }
      .padding()
      .background(Color.lightMain)
      .cornerRadius(5.0)
    }
  }
  
  struct FoundUserSection: View {
    var userId: String
    
    var body: some View {
      VStack {
        // User id
        HStack(alignment: .center) {
          Image(systemName: "person.crop.circle")
            .imageScale(.large)
            .foregroundColor(.main)
            .padding(.horizontal, 5)
          Text(userId)
            .font(.title)
            .bold()
            .foregroundColor(.main)
          Spacer()
        }
        .padding(.bottom, 20)
        
        // "Send a Partner Request" Button
        SendRequestButton(targetUserId: userId)
        
        // Caption text
        Text("The process to become a partner each other requires two steps. First you need to send a partner request. When a counterpart will receive and accept it, you two are become a partner each other.")
          .font(.caption)
          .lineSpacing(7)
          .foregroundColor(.black)
          .padding(.horizontal, 10)
      }
    }
  }
  
  struct SendRequestButton: View {
    var targetUserId: String
    @State var status: RequestStatus = .unsend
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: Store
    
    enum RequestStatus {
      case unsend
      case sending
      case sent
    }
    
    var body: some View {
      Button(action: { self.sendRequest() }) {
        HStack {
          Spacer()
          Text(self.text)
            .font(.headline)
            .foregroundColor(.white)
          Spacer()
        }
        .padding()
        .background(Color.main)
        .cornerRadius(10.0, antialiased: true)
        .shadow(color: Color(white: 0.8), radius: 5, x: 0, y: 2)
        .padding(.bottom, 20)
      }
    }
    
    var text: String {
      switch self.status {
      case .unsend:
        return "Send a Partner Request"
      case .sending:
        return "Sending..."
      case .sent:
        return "Request is sent"
      }
    }
    
    // TODO
    // Storeを経由する
    func sendRequest() {
      self.status = .sending
      
      self.store.sendPartnerRequest(toUserId: self.targetUserId) { res in
        switch res {
        case .success(()):
          self.status = .sent
        case .failure(_):
          self.status = .unsend
        }
      }
    }
  }
}

struct PartnerSearchView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NavigationView {
        let store = Store(me: Me(id: "usr_Ida84js", password: ""),
                          relationships: [],
                          receivedPartnerRequests: [])
        PartnerSearchView()
          .environmentObject(store)
          .previewDevice(PreviewDevice(rawValue: "init"))
          .previewDisplayName("init")
      }
      
      PartnerSearchView
        .MyInfoSection(me: Me(id: "usr_Isaje44", password: ""))
        .padding()
        .previewDevice(PreviewDevice(rawValue: "my info"))
        .previewDisplayName("my info")
      
      PartnerSearchView
        .FoundUserSection(userId: "usr_lkd2845n")
        .padding()
        .previewDevice(PreviewDevice(rawValue: "found"))
        .previewDisplayName("found")
    }
  }
}
