//
//  RelationshipView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/12/11.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RelationshipView: View {
    let relationship: Relationship
    
    var body: some View {
        ScrollView {
            if let nextCallTimeStr = self.nextCallTime {
                VStack(alignment: .leading) {
                    Text("Next call time")
                        .foregroundColor(.gray)
                    Text(nextCallTimeStr)
                        .font(.title)
                        .bold()
                    Divider()
                }
                .padding(.bottom, 30)
            }
            
            HStack {
                Text("Call schedules")
                    .font(.title)
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Schedules
            ForEach(relationship.callSchedules) { schedule in
                Card(bgColor: .lightMain) {
                    HStack {
                        Text("at")
                        Text("\(schedule.time.hour):\(schedule.time.min)")
                            .font(.headline)
                        Spacer()
                        Text("every")
                        Text(schedule
                                .weekdays
                                .map({ $0.rawValue.uppercased() })
                                .joined(separator: ", "))
                            .bold()
                    }
                }
                .padding(.bottom, 10)
            }
            
            // "Add a new call schedule" Button
            Card(bgColor: .main) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .imageScale(.large)
                        .foregroundColor(.white)
                    Text("Add a new call schedule")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                }
            }
        }
        .padding()
        .navigationBarTitle(relationship.partner.id)
    }
    
    var nextCallTime: String? {
        guard let date = relationship.nextCallTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RelationshipView_Previews: PreviewProvider {
    static var previews: some View {
        let callSchedule = CallSchedule(
            id: UUID(),
            time: Time(hour: 11, min: 42),
            weekdays: [.sun, .fri])
        let relationship = Relationship(
            id: UUID(),
            partner: User.demo,
            callSchedules: [callSchedule],
            nextCallTime: Date())
        
        return NavigationView {
            RelationshipView(relationship: relationship)
        }
    }
}
