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
    let partner: Partner
    let nextCallTime: Date
    
    static let demo = Relationship(id: UUID(), partner: Partner.demo, nextCallTime: Date())
}
