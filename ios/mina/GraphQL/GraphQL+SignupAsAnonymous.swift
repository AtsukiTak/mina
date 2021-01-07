//
//  GraphQL+SignupAsAnonymous.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct SignupAsAnonymous: Query {
    
    let query = """
    mutation SignupAsAnonymous {
        signupAsAnonymous {
            user {
                id
            }
            secret
        }
    }
    """
    
    let variables: [String : JSON]? = nil
    
    struct Data: Decodable {
      
      let signupAsAnonymous: Data.SignupAsAnonymous
      
      struct SignupAsAnonymous: Decodable {
        
        let user: SignupAsAnonymous.User
        let secret: String
        
        struct User: Decodable {
          
          let id: String
        }
      }
    }
  }
}
