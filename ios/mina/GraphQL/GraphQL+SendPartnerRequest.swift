//
//  GraphQL+SendPartnerRequest.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct SendPartnerRequest: Query {
    
    let toUserId: String
    
    let query = """
    mutation SendPartnerRequest($toUserId: String!) {
        sendPartnerRequest(toUserId: $toUserId)
    }
    """
    
    var variables: [String : JSON]? {
      return ["toUserId": .string(toUserId)]
    }
    
    struct Data: Decodable {
      
      var sendPartnerRequest: String
    }
  }
}
