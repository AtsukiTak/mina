//
//  Relationship.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/20.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct Relationship: Identifiable {
    let id: UUID
    let partner: User
    let callSchedules: [CallSchedule]
    let nextCallTime: Date?
    
    static let demo = Relationship(id: UUID(),
                                   partner: User.demo,
                                   callSchedules: [],
                                   nextCallTime: Date())
}

struct CallSchedule: Identifiable {
    let id: UUID
    let time: Time
    let weekdays: [Weekday]
}

enum Weekday: String {
    case sun = "sun"
    case mon = "mon"
    case tue = "tue"
    case wed = "wed"
    case thu = "thu"
    case fri = "fri"
    case sat = "sat"
}

struct Time: Equatable {
    // 0 ~ 23
    let hour: UInt
    // 0 ~ 59
    let min: UInt
    
    // # Panic
    // if "hour" >= 24 or "min" >= 60
    init(hour: UInt, min: UInt) {
        precondition(hour <= 23)
        precondition(min <= 59)
        
        self.hour = hour
        self.min = min
    }
}
