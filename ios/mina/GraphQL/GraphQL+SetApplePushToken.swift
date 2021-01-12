//
//  GraphQL+SetApplePushToken.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/12.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct SetApplePushToken: Query {
    
    let applePushToken: String
    
    let query = """
    mutation SetApplePushToken($token: String!) {
        setApplePushToken(applePushToken: $token) {
            id
        }
    }
    """
    
    var variables: [String : JSON]? {
      return [
        "token": .string(applePushToken)
      ]
    }
    
    struct Data: Decodable {
      let setApplePushToken: Data.SetApplePushToken
      
      struct SetApplePushToken: Decodable {
        let id: String
      }
    }
  }
}
