//
//  GraphQL+GetMe.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {

  struct GetMe: Query {
    
    let query = """
    query GetMe {
        me {
            id
            name
            applePushToken
            relationships {
                id
                partner {
                    id
                    name
                }
                callSchedules {
                    id
                    time
                    weekdays
                }
                nextCallTime
            }
            receivedPartnerRequests {
                id
                from {
                    id
                    name
                }
                to {
                    id
                    name
                }
                isValid
            }
        }
    }
    """
    
    var variables: [String : JSON]? = nil
    
    struct Data: Decodable {
      var me: Data.Me
      
      struct Me: Decodable {
        var id: String
        var name: String?
        var applePushToken: String?
        var relationships: [Me.Relationship]
        var receivedPartnerRequests: [Me.ReceivedPartnerRequest]
        
        struct Relationship: Decodable {
          var id: String
          var partner: Relationship.Partner
          var callSchedules: [Relationship.CallSchedule]
          var nextCallTime: String?
          
          struct Partner: Decodable {
            var id: String
            var name: String
          }
          
          struct CallSchedule: Decodable {
            var id: String
            var time: String
            var weekdays: String
          }
        }
        
        struct ReceivedPartnerRequest: Decodable {
          var id: String
          var from: ReceivedPartnerRequest.From
          var to: ReceivedPartnerRequest.To
          var isValid: Bool
          
          struct From: Decodable {
            var id: String
            var name: String
          }
          
          struct To: Decodable {
            var id: String
            var name: String
          }
        }
      }
    }
  }
}
