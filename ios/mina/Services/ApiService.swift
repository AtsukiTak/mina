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
    
    static let url: String = "https://api.mina.atsuki.me"
    
    static var shared: ApiService = ApiService()
    
    // ApolloClientを生成する
    static func apollo() -> ApolloClient {
        return ApolloClient(url: URL(string: url)!)
    }
    
    // Weekday構造体の配列を文字列からパースする
    // e.g. "sun,mon" -> [.sun, .mon]
    private static func parseWeekdayArray(_ s: String) throws -> [Weekday] {
        try s.split(separator: ",")
            .map({ s in try parseWeekday(String(s))})
    }
    
    // Weekday構造体を文字列からパースする
    // e.g. "sun" -> Weekday.sun
    private static func parseWeekday(_ s: String) throws -> Weekday {
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
    private static func parseTime(_ s: String) throws -> Time {
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
    private static func parseDate(_ s: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: s) else {
            throw ApiError.badResponse
        }
        return date
    }
    
    // UUID構造体をStringからパースする
    private static func parseUUID(_ s: String) throws -> UUID {
        guard let id = UUID(uuidString: s) else { throw ApiError.badResponse }
        return id
    }
    
    /*
     ==============
     Get Me
     ==============
     */
    struct GetMeOutput {
        var relationships: [Relationship]
        var receivedPartnerRequests: [PartnerRequest]
    }
    
    static func getMe(callback: @escaping (Result<GetMeOutput, Error>) -> Void) {
        apollo().fetch(query: GetMeQuery()) { result in
            do {
                let res = try result.get()
                
                let relationships = try res.data!.me.relationships.map { rel -> Relationship in
                    let id = try parseUUID(rel.id)
                    let partner = User(id: rel.partner.id)
                    let schedules = try rel.callSchedules.map { sche in
                        CallSchedule(time: try parseTime(sche.time),
                                     weekdays: try parseWeekdayArray(sche.weekdays))
                    }
                    let nextCallTime = try rel.nextCallTime.map(parseDate)
                    
                    return Relationship(id: id,
                                        partner: partner,
                                        callSchedules: schedules,
                                        nextCallTime: nextCallTime)
                }
                
                let receivedPartnerRequests = try res.data!.me.receivedPartnerRequests.map { req in
                    PartnerRequest(id: try parseUUID(req.id),
                                   from: User(id: req.from.id),
                                   to: User(id: req.to.id))
                }
                
                let output = GetMeOutput(relationships: relationships,
                                         receivedPartnerRequests: receivedPartnerRequests)
                
                callback(.success(output))
            } catch {
                callback(.failure(error))
            }
        }
    }
}
