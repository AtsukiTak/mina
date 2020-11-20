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
    @State var relationships: [Relationship]
    
    var body: some View {
        VStack {
            UserInfoSection(userId: self.userId)
            
            // partner cards
            ForEach(self.relationships, content: { relationship in
                PartnerCard(relationship: relationship)
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
            })
            
            // Add a new partner card
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
            
            Spacer()
        }
    }
}

struct UserInfoSection: View {
    let userId: String
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("ID :")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(self.userId)
                    .font(.body)
                    .foregroundColor(.purple)
                
                Spacer()
            }
            Divider()
        }
        .padding(.leading, 20)
    }
}

struct FirstView_Previews: PreviewProvider {
    static var previews: some View {
        FirstView(userId: "usr_74Jlei8d", relationships: [Relationship.demo, Relationship.demo])
    }
}
