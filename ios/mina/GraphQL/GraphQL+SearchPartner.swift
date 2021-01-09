//
//  GraphQL+SearchPartner.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/08.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct SearchPartner: Query {
    
    let userId: String
    
    let query = """
    query SearchPartner($userId: String!) {
        user(id: $userId) {
            id
            name
        }
    }
    """
    
    var variables: [String : GraphQL.JSON]? {
      ["userId": .string(userId)]
    }
    
    struct Data: Decodable {
      let user: Data.User
      
      struct User: Decodable {
        let id: String
        let name: String?
      }
    }
  }
}
