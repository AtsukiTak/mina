//
//  GraphQL+AcceptPartnerRequest.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct AcceptPartnerRequest: Query {
    
    let requestId: UUID
    
    let query = """
    mutation AcceptPartnerRequest($requestId: UUID!) {
        acceptPartnerRequest(requestId: $requestId)
    }
    """
    
    var variables: [String : JSON]? {
      return ["requestId": .string(self.requestId.uuidString)]
    }
    
    struct Data: Decodable {
      let acceptPartnerRequest: String
    }
  }
}
