//
//  GraphQL+AddCallSchedule.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

extension GraphQL {
  
  struct AddCallSchedule: Query {
    
    let addCallScheduleInput: GraphQL.AddCallScheduleInput
    
    let query = """
    mutation AddCallSchedule($input: AddCallScheduleInput!) {
        addCallSchedule(input: $input) {
            id
            callSchedules {
                id
                time
                weekdays
            }
            nextCallTime
        }
    }
    """
    
    var variables: [String : JSON]? {
      let input = self.addCallScheduleInput
      return [
        "relationshipId": .string(input.relationshipId),
        "weekdays": .string(input.weekdays),
        "time": .string(input.time)
      ]
    }
    
    struct Data: Decodable {
      
      let addCallSchedule: Data.AddCallSchedule
      
      struct AddCallSchedule: Decodable {
        
        let id: String
        let callSchedules: [AddCallSchedule.CallSchedule]
        let nextCallTime: String?
        
        struct CallSchedule: Decodable {
          
          let id: String
          let time: String
          let weekdays: String
        }
      }
    }
  }
}
