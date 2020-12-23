//
//  FirstView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/19.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct FirstView: View {
  @EnvironmentObject var store: Store
  
  var body: some View {
    NavigationView {
      ScrollView(.vertical, showsIndicators: false) {
        VStack {
          if !self.store.receivedPartnerRequests.isEmpty {
            self.receivedPartnerRequestsSection
              .padding(.bottom, 40)
          }
          
          self.partnersSection
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
      }
    }
  }
  
  var receivedPartnerRequestsSection: some View {
    VStack {
      self.sectionTitle(title: "Received Requests")
      
      ForEach(self.store.receivedPartnerRequests, content: { request in
        HStack(alignment: .lastTextBaseline) {
          Text(request.from.id)
            .font(.title)
            .foregroundColor(.main)
            .padding(.leading, 10)
          
          Spacer()
          
          AcceptPartnerRequestButton(request: request) { onComplete in
            self.store.acceptPartnerRequest(requestId: request.id, onComplete: onComplete)
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
      ForEach(self.store.relationships, content: { relationship in
        NavigationLink(destination: RelationshipView(relationship: relationship)) {
          PartnerCard(relationship: relationship)
            .padding(.horizontal, 15)
            .padding(.top, 20)
        }
      })
      
      // Add a new partner card
      NavigationLink(destination: PartnerSearchView()) {
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
    let acceptHandler: (_ onComplete: @escaping () -> Void) -> Void
    @State var status: Status = .initial
    
    init(request: PartnerRequest,
         acceptHandler: @escaping (_ onComplete: @escaping () -> Void) -> Void) {
      self.request = request
      self.acceptHandler = acceptHandler
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
      if self.status == .processing { return; }
      self.status = .processing
      
      self.acceptHandler { self.status = .initial }
    }
  }
}

struct FirstView_Previews: PreviewProvider {
  static var previews: some View {
    let env = Store()
    env.relationships = [Relationship.demo, Relationship.demo]
    env.receivedPartnerRequests = [PartnerRequest.demo]
    
    return FirstView()
      .environmentObject(env)
  }
}
