//
//  GraphQL.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/07.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

// All of these codes should be generated automatically.
struct GraphQL {
  
  struct Request<Q: Query> {
    
    var req: URLRequest
    
    init(endpoint: URL, query: Q) {
      var req = URLRequest(url: endpoint)
      req.httpMethod = "POST"
      req.addValue("application/json", forHTTPHeaderField: "content-type")
      
      let body = ReqBody(query: query)
      let encoder = JSONEncoder()
      req.httpBody = try! encoder.encode(body)
      
      self.req = req
    }
    
    struct ReqBody: Encodable {
      let query: String
      let operationName: String? // not be used at all for now
      let variables: [String:JSON]?
      
      init<Q: Query>(query: Q) {
        self.query = query.query
        self.operationName = nil
        self.variables = query.variables
      }
    }
  }
  
  enum JSON: Encodable {
    case bool(Bool)
    case number(Int)
    case string(String)
    case null
    case array([JSON])
    case object([String:JSON])
    
    struct ObjectKey: CodingKey {
      let key: String
      
      init(key: String) {
        self.key = key
      }
      
      init?(intValue: Int) {
        return nil
      }
      
      init?(stringValue: String) {
        self.key = stringValue
      }
      
      var stringValue: String {
        return self.key
      }
      
      let intValue: Int? = nil
    }
    
    func encode(to encoder: Encoder) throws {
      switch self {
      case .bool(let val):
        var container = encoder.singleValueContainer()
        try container.encode(val)
      case .number(let val):
        var container = encoder.singleValueContainer()
        try container.encode(val)
      case .string(let val):
        var container = encoder.singleValueContainer()
        try container.encode(val)
      case .null:
        var container = encoder.singleValueContainer()
        try container.encodeNil()
      case .array(let val):
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: val)
      case .object(let val):
        var container = encoder.container(keyedBy: ObjectKey.self)
        try val.forEach{ key, val in
          let objKey = ObjectKey(key: key)
          try container.encode(val, forKey: objKey)
        }
      }
    }
  }
  
  struct AddCallScheduleInput {
    let relationshipId: String
    let weekdays: String
    let time: String
  }
}

extension URLSession {
  func graphqlTask<Q: Query>(with req: GraphQL.Request<Q>,
                             onComplete: @escaping (Result<Q.Data, Error>) -> Void
  ) -> URLSessionDataTask {
    let task = self.dataTask(with: req.req) { data, res, err in
      if let err = err {
        onComplete(.failure(err))
      }
      
      if let data = data {
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(Q.Data.self, from: data)
          onComplete(.success(decoded))
        } catch {
          onComplete(.failure(error))
        }
      }
    }
    
    return task
  }
}

protocol Query {
  associatedtype Data: Decodable
  
  var query: String { get }
  var variables: [String:GraphQL.JSON]? { get }
}
