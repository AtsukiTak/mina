//
//  ApiService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import Combine
import Apollo

struct ApiService {
  enum ApiError: Error {
    case notSuccess(Int) // status code
    case badResponse
  }
  
  struct Parser {
    // Weekday構造体の配列を文字列からパースする
    // e.g. "sun,mon" -> [.sun, .mon]
    static func parseWeekdayArray(_ s: String) throws -> [Weekday] {
      try s.split(separator: ",")
        .map({ s in try parseWeekday(String(s))})
    }
    
    // Weekday構造体を文字列からパースする
    // e.g. "sun" -> Weekday.sun
    static func parseWeekday(_ s: String) throws -> Weekday {
      switch s.lowercased() {
      case "sun":
        return Weekday.sun
      case "mon":
        return Weekday.mon
      case "tue":
        return Weekday.tue
      case "wed":
        return Weekday.wed
      case "thu":
        return Weekday.thu
      case "fri":
        return Weekday.fri
      case "sat":
        return Weekday.sat
      default:
        throw ApiError.badResponse
      }
    }
    
    // Time構造体を文字列からパースする
    // e.g. "08:23" -> Time { hour: 8, min: 23 }
    static func parseTime(_ s: String) throws -> Time {
      let pattern = "(^[0-9]{2}:[0-9]{2}$)"
      let regex = try! NSRegularExpression(pattern: pattern, options: [])
      
      // Matchするかどうかだけ調べる
      if regex.numberOfMatches(in: s, options: [], range: NSRange(0..<5)) == 0 {
        throw ApiError.badResponse
      }
      
      // 1~2文字め
      let hourStr = s[s.startIndex..<s.index(s.startIndex, offsetBy: 2)]
      let hour = UInt(hourStr)! // 正規表現で保証している
      
      // 3~4文字め
      let minStr = s[s.index(s.startIndex, offsetBy: 3)..<s.endIndex]
      let min = UInt(minStr)! // 正規表現で保証している
      
      if (hour >= 24 || min >= 60) {
        throw ApiError.badResponse
      }
      
      return Time(hour: hour, min: min)
    }
    
    // Date構造体を文字列からパースする
    static func parseDate(_ s: String) throws -> Date {
      let formatter = ISO8601DateFormatter()
      guard let date = formatter.date(from: s) else {
        throw ApiError.badResponse
      }
      return date
    }
    
    // UUID構造体をStringからパースする
    static func parseUUID(_ s: String) throws -> UUID {
      guard let id = UUID(uuidString: s) else { throw ApiError.badResponse }
      return id
    }
  }
  
  struct Formatter {
    // Weekday構造体の配列を文字列にフォーマットする
    static func formatWeekdayArray(_ weekdays: [Weekday]) -> String {
      weekdays.map({ w in w.rawValue }).joined(separator: ",")
    }
    
    // Time構造体を文字列にフォーマットする
    static func formatTime(_ time: Time) -> String {
      let hour = String(format: "%02d", time.hour)
      let min = String(format: "%02d", time.min)
      return "\(hour):\(min)"
    }
    
    // UUID構造体をStringにフォーマットする
    static func formatUUID(_ id: UUID) -> String {
      return id.uuidString
    }
  }
  
  struct GraphqlApi {
    let endpoint: URL
    
    init() {
      self.endpoint = URL(string: Secrets.shared.graphqlEndpoint)!
    }
    
    /*
     ==============
     Get Me
     ==============
     */
    struct GetMyDataOutput {
      var relationships: [Relationship]
      var receivedPartnerRequests: [PartnerRequest]
    }
    
    func getMyData(me: Me, callback: @escaping (Result<GetMyDataOutput, Error>) -> Void) {
      let query = GraphQL.GetMe()
      var req = GraphQL.Request(endpoint: self.endpoint, query: query)
      req.req.addValue(GraphqlApi.basicAuthVal(me), forHTTPHeaderField: "Authorization")
      
      let task = URLSession.shared.graphqlTask(with: req) { result in
        do {
          let data = try result.get()
          
          let relationships = try data.me.relationships.map { rel -> Relationship in
            let id = try ApiService.Parser.parseUUID(rel.id)
            let partner = User(id: rel.partner.id)
            let schedules = try rel.callSchedules.map { sche in
              CallSchedule(
                id: try ApiService.Parser.parseUUID(sche.id),
                time: try ApiService.Parser.parseTime(sche.time),
                weekdays: try ApiService.Parser.parseWeekdayArray(sche.weekdays))
            }
            let nextCallTime = try rel.nextCallTime.map(ApiService.Parser.parseDate)
            
            return Relationship(id: id,
                                partner: partner,
                                callSchedules: schedules,
                                nextCallTime: nextCallTime)
          }
          
          let receivedPartnerRequests = try data.me.receivedPartnerRequests.map { req in
            PartnerRequest(id: try ApiService.Parser.parseUUID(req.id),
                           from: User(id: req.from.id),
                           to: User(id: req.to.id))
          }
          
          let output = GetMyDataOutput(relationships: relationships,
                                   receivedPartnerRequests: receivedPartnerRequests)
          
          callback(.success(output))
        } catch {
          callback(.failure(error))
        }
      }
      task.resume()
    }
    
    /*
     ===============
     Signup
     ===============
     */
    func signupAsAnonymous(callback: @escaping (Result<Me, Error>) -> Void) {
      let query = GraphQL.SignupAsAnonymous()
      let req = GraphQL.Request(endpoint: self.endpoint, query: query)
      
      let task = URLSession.shared.graphqlTask(with: req) { result in
        switch result {
        case .success(let data):
          let data = data.signupAsAnonymous
          let me = Me(id: data.user.id, password: data.secret)
          callback(.success(me))
        case .failure(let err):
          callback(.failure(err))
        }
      }
      task.resume()
    }
    
    /*
     ======================
     Send Partner Request
     ======================
     */
    func sendPartnerRequest(me: Me, toUserId: String, callback: @escaping (Result<(), Error>) -> Void) {
      let query = GraphQL.SendPartnerRequest(toUserId: toUserId)
      var req = GraphQL.Request(endpoint: self.endpoint, query: query)
      req.req.addValue(GraphqlApi.basicAuthVal(me), forHTTPHeaderField: "Authorization")
      
      let task = URLSession.shared.graphqlTask(with: req) { res in
        switch res {
        case .success(_):
          callback(.success(()))
        case .failure(let err):
          callback(.failure(err))
        }
      }
      task.resume()
    }
    
    /*
     =======================
     Accept Partner Request
     =======================
     */
    func acceptPartnerRequest(me: Me, requestId: UUID, callback: @escaping (Result<(), Error>) -> Void) {
      let query = GraphQL.AcceptPartnerRequest(requestId: requestId)
      var req = GraphQL.Request(endpoint: self.endpoint, query: query)
      req.req.addValue(GraphqlApi.basicAuthVal(me), forHTTPHeaderField: "Authorization")
      
      let task = URLSession.shared.graphqlTask(with: req) { result in
        switch result {
        case .success(_):
          callback(.success(()))
        case .failure(let err):
          callback(.failure(err))
        }
      }
      task.resume()
    }
    
    /*
     =======================
     Add Call Schedule
     =======================
     */
    func addCallSchedule(me: Me,
                         relationship: Relationship,
                         time: Time,
                         weekdays: [Weekday],
                         callback: @escaping (Result<Relationship, Error>) -> Void) {
      // requestの生成
      let input = GraphQL.AddCallScheduleInput(
        relationshipId: ApiService.Formatter.formatUUID(relationship.id),
        weekdays: ApiService.Formatter.formatWeekdayArray(weekdays),
        time: ApiService.Formatter.formatTime(time))
      let query = GraphQL.AddCallSchedule(addCallScheduleInput: input)
      var req = GraphQL.Request(endpoint: self.endpoint, query: query)
      req.req.addValue(GraphqlApi.basicAuthVal(me), forHTTPHeaderField: "Authorization")
      
      // requestの実行
      let task = URLSession.shared.graphqlTask(with: req) { result in
        do {
          let data = try result.get().addCallSchedule
          let schedules = try data.callSchedules.map { sche in
            CallSchedule(
              id: try ApiService.Parser.parseUUID(sche.id),
              time: try ApiService.Parser.parseTime(sche.time),
              weekdays: try ApiService.Parser.parseWeekdayArray(sche.weekdays))
          }
          let nextCallTime = try data.nextCallTime.map(ApiService.Parser.parseDate)
          
          let newRelationship = Relationship(id: relationship.id,
                                             partner: relationship.partner,
                                             callSchedules: schedules,
                                             nextCallTime: nextCallTime)
          callback(.success(newRelationship))
        } catch {
          callback(.failure(error))
        }
      }
      task.resume()
    }
    
    /*
     =================
     Utility funcion
     =================
     */
    static func basicAuthVal(_ me: Me) -> String {
      let credData = "\(me.id):\(me.password)".data(using: String.Encoding.utf8)!
      let credential = credData.base64EncodedString(options: [])
      return "Basic \(credential)"
    }
  }
  
  struct PublicApi {
    let apollo: ApolloClient
    
    init() {
      let graphqlEndpoint = Secrets.shared.graphqlEndpoint
      self.init(graphqlEndpoint: graphqlEndpoint)
    }
    
    init (graphqlEndpoint: String) {
      
      self.apollo = ApolloClient(url: URL(string: graphqlEndpoint)!)
    }
    
    
    
    /*
     ================
     SearchPartner
     ================
     */
    func searchPartner(userId: String, callback: @escaping (Result<User, Error>) -> Void) {
      apollo.fetch(query: SearchPartnerQuery(userId: userId)) { result in
        do {
          let res = try result.get()
          let data = res.data!
          let user = User(id: data.user.id)
          callback(.success(user))
        } catch {
          callback(.failure(error))
        }
      }
    }
  }
  
  struct PrivateApi {
    let apollo: ApolloClient
    let me: Me
    
    init(me: Me) {
      let graphqlEndpoint = Secrets.shared.graphqlEndpoint
      self.init(me: me, graphqlEndpoint: graphqlEndpoint)
    }
    
    init(me: Me, graphqlEndpoint: String) {
      self.me = me
      
      // Basic認証用の文字列の生成
      let credData = "\(me.id):\(me.password)".data(using: String.Encoding.utf8)!
      let credential = credData.base64EncodedString(options: [])
      let basicAuth = "Basic \(credential)"
      
      // ApolloClientの生成
      let store = ApolloStore()
      let network = RequestChainNetworkTransport(
        interceptorProvider: LegacyInterceptorProvider(store: store),
        endpointURL: URL(string: graphqlEndpoint)!,
        additionalHeaders: ["Authorization": basicAuth],
        autoPersistQueries: false,
        requestBodyCreator: ApolloRequestBodyCreator(),
        useGETForQueries: false,
        useGETForPersistedQueryRetry: false)
      let apollo = ApolloClient(networkTransport: network, store: store)
      
      self.apollo = apollo
    }
    
    
    
    
    
    
    
    
  }
}
