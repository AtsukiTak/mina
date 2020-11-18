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
    }
    
    let url: String = "https://api.mina.atsuki.me"
    
    static var shared: ApiService = ApiService()
    
    private(set) lazy var apollo = ApolloClient(url: URL(string: url)!)
}
