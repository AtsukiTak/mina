//
//  FirstView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/19.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct FirstView: View {
    @State var userId: String
    @State var relationships: [Relationship] = []
    @State var requests: [PartnerRequest] = []
    @State private var searchMode: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                if !self.requests.isEmpty {
                    self.receivedPartnerRequestsSection
                        .padding(.bottom, 40)
                }
                
                self.partnersSection
                    .padding(.bottom, 40)
            }
        }
    }
    
    var receivedPartnerRequestsSection: some View {
        VStack {
            self.sectionTitle(title: "Received Requests")
            
            ForEach(self.requests, content: { request in
                HStack(alignment: .lastTextBaseline) {
                    Text(request.from.id)
                        .font(.title)
                        .foregroundColor(.main)
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    // Completeしたらリストから消す
                    AcceptPartnerRequestButton(request: request) {
                        self.requests.removeAll { req in
                            req.id == request.id
                        }
                    }
                }
                .padding()
            })
        }
    }
    
    var partnersSection: some View {
        VStack {
            self.sectionTitle(title: "Partners")
            
            // partner cards
            ForEach(self.relationships, content: { relationship in
                PartnerCard(relationship: relationship)
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
            })
            
            // Add a new partner card
            Button(action: { self.searchMode = true}) {
                Card(bgColor: Color.main) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .imageScale(.large)
                            .foregroundColor(.white)
                        Text("Add a new partner")
                            .foregroundColor(.white)
                            .bold()
                        Spacer()
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 20)
            }
            .sheet(isPresented: self.$searchMode) {
                PartnerSearchView()
            }
            
            Spacer()
        }
    }
    
    func sectionTitle(title: String) -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title)
                    .bold()
                Spacer()
            }
            .padding(.leading, 15)
            
            Divider()
                .padding(.leading, 15)
        }
    }
    
    struct AcceptPartnerRequestButton: View {
        let request: PartnerRequest
        let onComplete: () -> Void
        @State var status: Status = .initial
        
        init(request: PartnerRequest, onComplete: @escaping () -> Void) {
            self.request = request
            self.onComplete = onComplete
        }
        
        enum Status {
            case initial
            case processing
            case completed
        }
        
        var body: some View {
            Button(action: { self.accept() }) {
                Text(self.text)
                    .foregroundColor(.white)
                    .padding(15)
                    .background(Color.main)
                    .cornerRadius(10.0)
                    .shadow(color: Color(white: 0.8), radius: 5, x: 0, y: 2)
            }
        }
        
        var text: String {
            switch self.status {
            case .initial:
                return "Accept"
            case .processing:
                return "Processing..."
            case .completed:
                return "Complete!"
            }
        }
        
        func accept() {
            self.status = .processing
            
            let mutation = AcceptPartnerRequestMutation(requestId: self.request.id.uuidString)
            ApiService.shared.apollo.perform(mutation: mutation) { result in
                switch result {
                case .success(_):
                    self.status = .completed
                    self.onComplete()
                case .failure(_):
                    self.status = .initial
                }
            }
        }
    }
}

struct FirstView_Previews: PreviewProvider {
    static var previews: some View {
        FirstView(userId: "usr_74Jlei8d",
                  relationships: [Relationship.demo, Relationship.demo],
                  requests: [PartnerRequest.demo])
    }
}
