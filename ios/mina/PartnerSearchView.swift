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
    @State var requestStatus: RequestStatus = .unsend
    
    enum RequestStatus {
        case unsend
        case sending
        case sent
    }
    
    var body: some View {
        VStack {
            TextField("Input partner's user id", text: $input,
                      onEditingChanged: { _ in },
                      onCommit: { self.searchPartner() }
                )
                .padding(.bottom, 20)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .transition(.slide)
            
            if let userId = foundUserId {
                Divider()
                Spacer()
                self.foundUserSection(userId: userId)
                    .transition(.opacity)
                Spacer()
            }
        }
        .padding()
        .animation(.easeInOut)
    }
    
    func foundUserSection(userId: String) -> some View {
        VStack {
            // User id
            HStack(alignment: .center) {
                Image(systemName: "person.crop.circle")
                    .imageScale(.large)
                    .foregroundColor(.main)
                    .padding(.horizontal, 10)
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
    
    func searchPartner() {
        ApiService.shared.apollo.fetch(query: SearchPartnerQuery(userId: self.input)) { result in
            switch result {
            case .success(let res):
                self.foundUserId = res.data!.user.id
            case .failure(_): break // TODO
            }
        }
    }
}

struct SendRequestButton: View {
    var targetUserId: String
    @State var status: RequestStatus = .unsend
    @Environment(\.presentationMode) var presentationMode
    
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
    
    func sendRequest() {
        self.status = .sending

        let mutation = SendPartnerRequestMutation(toUserId: self.targetUserId)
        ApiService.shared.apollo.perform(mutation: mutation) { result in
            switch result {
            case .success(_):
                self.status = .sent
            case .failure(_):
                self.status = .unsend
                // TODO : show error msg
            }
        }
    }
}

struct PartnerSearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PartnerSearchView()
                .previewDevice(PreviewDevice(rawValue: "init"))
                .previewDisplayName("init")
            
            PartnerSearchView(foundUserId: "usr_lkd2845n")
                .previewDevice(PreviewDevice(rawValue: "searched"))
                .previewDisplayName("searched")
        }
    }
}
