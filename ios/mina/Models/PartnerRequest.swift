//
//  PartnerRequest.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct PartnerRequest: Identifiable {
    let id: UUID
    let from: User
    let to: User
    
    static let demo: PartnerRequest = PartnerRequest(id: UUID(), from: User.demo, to: User.demo)
}
