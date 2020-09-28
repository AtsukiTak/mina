//
//  ApiService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import Combine

struct ApiService {
    enum ApiError: Error {
        case notSuccess(Int) // status code
    }
    
    let baseUrl: String = "https://api.mina.atsuki.me"
    
    struct CreateUserRes: Codable {
        let id: String
    }
    
    func createUser(password: String) -> AnyPublisher<CreateUserRes, Error> {
        struct Req: Codable {
            let password: String
        }
        
        let body = try! JSONEncoder().encode(Req(password: password))
        
        return self.post("/users", body)
    }
    
    private func post<T>(_ endpoint: String,
                 _ body: Data) -> AnyPublisher<T, Error>
        where T: Decodable
    {
        let url = URL(string: self.baseUrl + endpoint)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .tryMap { (data, res) in
                let httpRes = res as! HTTPURLResponse
                if (200..<300).contains(httpRes.statusCode) == false {
                    throw ApiError.notSuccess(httpRes.statusCode)
                }
                return data
            }
        .decode(type: T.self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
    }
}
