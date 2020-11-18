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
    let password: String
    
    var credential: Credential {
        Credential(userId: id, password: password)
    }
}

struct Credential {
    let userId: String
    let password: String
}

struct UserRepository {
    static func findUser() throws -> User? {
        try KeychainService()
            .readCred()
            .map { User(id: $0.userId, password: $0.password) }
    }
}
