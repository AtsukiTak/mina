//
//  ApiService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct ApiService {
    enum ApiResult<T> {
        case Success(T)
        case Error(ApiError)
    }
    
    enum ApiError: Error {
        case NetworkError(Error)
        case InvalidResponse(Data?)
    }
    
    let baseUrl: String = "https://api.mina.atsuki.me"
    
    func createUser(password: String,
                    completeHandler: @escaping (ApiResult<User>) -> Void) {
        struct Req: Codable {
            let password: String
        }
        
        struct Res: Codable {
            let id: String
        }
        
        let body = try! JSONEncoder().encode(Req(password: password))
        
        self.post("/users", body) { (res: ApiResult<Res>) in
            switch res {
            case .Success(let data):
                return completeHandler(.Success(User(id: data.id)))
            case .Error(let err):
                return completeHandler(.Error(err))
            }
        }
    }
    
    func post<T>(_ endpoint: String,
                 _ body: Data,
                 completeHandler: @escaping (ApiResult<T>) -> Void
    ) where T: Decodable
    {
        let url = URL(string: self.baseUrl + endpoint)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        
        let task = URLSession.shared.dataTask(with: req) { (data, res, err) in
            if let err = err {
                print("Network error: \(err)")
                return completeHandler(.Error(.NetworkError(err)))
            }
            
            guard let data = data else {
                print("Empty response")
                return completeHandler(.Error(.InvalidResponse(nil)))
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return completeHandler(.Success(decoded))
            } catch {
                print("Invalid Response")
                return completeHandler(.Error(.InvalidResponse(data)))
            }
        }
        task.resume()
    }
}
