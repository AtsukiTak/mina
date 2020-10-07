//
//  GlobalEnvironment.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

class GlobalEnvironment: ObservableObject {
    @Published var callMode: Bool = false
    
    static let shared = GlobalEnvironment()
    
    private init() {}
}
