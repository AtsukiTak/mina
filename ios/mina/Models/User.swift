//
//  User.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import Combine

struct User {
    let id: String
    
    static let demo = User(id: "usr_4Jlsij83")
}

struct Me: Equatable {
    let id: String
    let password: String
}
