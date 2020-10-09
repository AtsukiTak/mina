//
//  Secrets.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/09.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct Secrets: Codable {
    let skywayApiKey: String
    let skywayDomain: String
    
    static let shared: Secrets = load()
    
    private static func load() -> Secrets {
        // secrets.plist ファイルの読み込み
        let secretsURL: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "secrets", ofType: "plist")!)
        let data = try! Data(contentsOf: secretsURL)
        let decoder = PropertyListDecoder()
        return try! decoder.decode(Secrets.self, from: data)
    }
}
