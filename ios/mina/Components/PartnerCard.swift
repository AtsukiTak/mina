//
//  Card.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/20.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct PartnerCard: View {
    let relationship: Relationship
    
    var body: some View {
        Card(bgColor: Color.lightMain) {
            VStack {
                HStack(alignment: .bottom) {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.large)
                        .foregroundColor(.main)
                        .padding(.trailing, 5)
                    Text(self.relationship.partner.id)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.main)
                    Spacer()
                }
                .padding(.bottom, 20)
                
                // Next call section
                HStack {
                    VStack(alignment: .leading) {
                        Text("Next Call")
                            .font(.caption)
                            .foregroundColor(.main)
                            .bold()
                            .offset(x: 0, y: -3)
                        Text(self.nextCallStr)
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
            }
        }
    }
    
    var nextCallStr: String {
        guard let nextCallTime = self.relationship.nextCallTime else {
            return "-";
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: nextCallTime)
    }
}

struct PartnerCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PartnerCard(relationship: Relationship.demo)
                .padding()
            
            PartnerCard(relationship: Relationship(id: UUID(),
                                                   partner: User.demo,
                                                   callSchedules: [],
                                                   nextCallTime: nil))
                .padding()
        }
    }
}
