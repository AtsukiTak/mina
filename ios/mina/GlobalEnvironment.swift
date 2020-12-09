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
    @Published var relationships: [Relationship] = []
    @Published var partnerRequests: [PartnerRequest] = []
    @Published var errorText: String? = nil
    
    init() {}
    
    func queryInitial() {
        ApiService.getMe { res in
            switch res {
            case .failure(let err):
                self.errorText = err.localizedDescription
            case .success(let output):
                self.errorText = nil
                self.relationships = output.relationships
                self.partnerRequests = output.receivedPartnerRequests
            }
        }
    }
}
