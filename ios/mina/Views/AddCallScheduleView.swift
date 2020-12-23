//
//  AddCallScheduleView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/12/11.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct AddCallScheduleView: View {
  let relationship: Relationship
  
  @State var selectedHour = 12
  @State var selectedMinute = 30
  @State var selectedWeekdays: Set<Weekday> = [.wed]
  @State var saving = false
  
  @Environment(\.presentationMode) var presentation
  @EnvironmentObject var store: Store
  
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
    VStack {
      Spacer()
      TimeSelector(selectedHour: self.$selectedHour,
                   selectedMinute: self.$selectedMinute)
      
      Spacer()
      
      WeekdaySelector(selectedWeekdays: self.$selectedWeekdays)
      
      Spacer()
      
      // 保存ボタン
      Button(action: onSubmit) {
        Text("Save")
          .font(.title)
          .bold()
          .padding(.horizontal, 50)
          .padding(.vertical, 20)
          .background(Color.main)
          .foregroundColor(.white)
          .cornerRadius(10)
          .shadow(color: Color(white: 0.8), radius: 5, x: 0, y: 2)
      }
      .disabled(self.saving)
      
      Spacer()
    }
    .padding()
    .navigationBarTitle("Add a call schedule")
  }
  
  func onSubmit() {
    self.saving = true
    
    let time = Time(hour: UInt(self.selectedHour), min: UInt(self.selectedMinute))
    self.store.addCallSchedule(relationshipId: self.relationship.id,
                               time: time,
                               weekdays: Array(self.selectedWeekdays)) { () in
      // 前の画面に戻る
      self.presentation.wrappedValue.dismiss()
    }
  }
  
  struct TimeSelector: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    var body: some View {
      HStack {
        Text("Time:")
          .font(.title)
        
        Spacer()
        
        Picker(selection: $selectedHour, label: Text("Hour")) {
          ForEach(0..<24) {
            Text("\($0)")
              .font(.title)
          }
        }
        .labelsHidden()
        .frame(width: 70, height: 100, alignment: .center)
        .clipped()
        
        Text(":")
        
        Picker(selection: $selectedMinute, label: Text("Minute")) {
          ForEach(0..<60, id: \.self) {
            Text("\($0)")
              .font(.title)
          }
        }
        .labelsHidden()
        .frame(width: 70, height: 100, alignment: .center)
        .clipped()
      }
    }
  }
  
  struct WeekdaySelector: View {
    @Binding var selectedWeekdays: Set<Weekday>
    
    var body: some View {
      HStack(alignment: .center) {
        Spacer()
        ForEach(Weekday.allCases, id: \.self) { weekday in
          WeekdayToggle(
            weekday: weekday,
            isActive: self.selectedWeekdays.contains(weekday),
            onToggle: {
              self.selectedWeekdays = self.selectedWeekdays.symmetricDifference([weekday])
            })
          Spacer()
        }
      }
    }
  }
  
  struct WeekdayToggle: View {
    let weekday: Weekday
    let isActive: Bool
    let onToggle: () -> Void
    
    var body: some View {
      Button(action: {
        self.onToggle()
      }, label: {
        if self.isActive {
          Text("\(self.weekday.rawValue)")
            .font(.body)
            .bold()
        } else {
          Text("\(self.weekday.rawValue)")
            .font(.body)
            .foregroundColor(.gray)
        }
      })
    }
  }
}

struct AddCallScheduleView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AddCallScheduleView(relationship: Relationship.demo)
        .environmentObject(Store())
    }
  }
}
