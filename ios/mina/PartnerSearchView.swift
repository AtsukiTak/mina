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
    @State var sendingRequest: Bool = false
    
    var body: some View {
        VStack {
            Text("Search partner")
                .font(.headline)
                .foregroundColor(.primary)
                .padding()
            TextField("Input partner's user id", text: $input,
                      onEditingChanged: { _ in },
                      onCommit: { self.searchPartner() }
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            if let userId = foundUserId {
                Divider()
                    .padding()
                HStack(alignment: .center) {
                    Text(userId)
                        .font(.headline)
                    Spacer()
                    SendRequestButton(targetUserId: userId)
                }
                .padding()
            }
            Spacer()
        }
    }
    
    func searchPartner() {
        ApiService.shared.apollo.fetch(query: SearchPartnerQuery(userId: self.input)) { result in
            switch result {
            case .success(let res):
                self.foundUserId = res.data!.user.id
            case .failure(_): break
            }
        }
    }
}

struct SendRequestButton: View {
    var targetUserId: String
    @State var status: ButtonStatus = .initial
    
    enum ButtonStatus {
        case initial
        case sending
        case completed
    }
    
    var body: some View {
            switch self.status {
            case .initial:
                Button(action: self.sendRequest) {
                    Text("Send Request")
                        .font(.footnote)
                        .foregroundColor(.purple)
                        .bold()
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 25)
                                    .stroke(lineWidth: 2.0)
                                    .foregroundColor(.purple))
                }
            case .sending:
                Text("Sending...")
                    .font(.footnote)
                    .foregroundColor(.purple)
                    .bold()
                    .padding(12)
                    .overlay(RoundedRectangle(cornerRadius: 25)
                                .stroke(lineWidth: 2.0)
                                .foregroundColor(.purple))
            case .completed:
                Text("Complete!")
                    .font(.footnote)
                    .bold()
                    .padding(15)
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(25)
            }
    }
    
    func sendRequest() {
        self.status = .sending
        return;

        ApiService.shared.apollo.perform(mutation: SendPartnerRequestMutation(toUserId: self.targetUserId)) { result in
            // TODO
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
