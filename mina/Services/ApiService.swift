//
//  ApiService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/24.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct ApiService {
    let baseUrl: String = "https://api.mina.atsuki.me"
    
    func createUser(password: String, onSuccess: @escaping (User) -> Void) throws {
        struct Res: Codable {
            let id: String
        }
        
        let url = URL(string: baseUrl + "/users")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        // TODO: passwordをbodyに指定する
        
        let task = URLSession.shared.dataTask(with: req) { (data, res, err) in
            guard let data = data else { return }
            do {
                let id = try JSONDecoder().decode(Res.self, from: data).id
                return onSuccess(User(id: id))
            } catch let e {
                print("Json Decode Error: \(e)")
                return
            }
        }
        task.resume()
    }
}
