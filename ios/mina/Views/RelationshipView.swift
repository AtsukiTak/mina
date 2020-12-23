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
  
  init(relationship: Relationship) {
    self.relationship = relationship
    
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
        .padding(.bottom, 50)
      }
      
      HStack {
        Text("Call schedules")
          .font(.title)
        Spacer()
      }
      .padding(.bottom, 20)
      
      // Schedules
      ForEach(relationship.callSchedules) { schedule in
        Card(bgColor: .lightMain) {
          VStack {
            HStack(alignment: .bottom) {
              Image(systemName: "calendar")
                .imageScale(.large)
                .foregroundColor(.main)
              Spacer()
              Text("\(schedule.time.hour):\(schedule.time.min)")
                .font(.largeTitle)
                .foregroundColor(.main)
            }
            HStack(alignment: .bottom) {
              Spacer()
              Text(schedule
                    .weekdays
                    .map({ $0.rawValue.uppercased() })
                    .joined(separator: ", "))
                .font(.caption)
                .bold()
                .foregroundColor(.main)
            }
          }
        }
        .padding(.bottom, 20)
      }
      
      // "Add a new call schedule" Button
      NavigationLink(destination: AddCallScheduleView(relationship: relationship)) {
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
    return NavigationView {
      RelationshipView(relationship: Relationship.demo)
    }
  }
}
