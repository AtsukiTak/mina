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
    @Published var me: Me? = nil
    @Published var relationships: [Relationship] = []
    @Published var receivedPartnerRequests: [PartnerRequest] = []
    @Published var errorText: String? = nil
    
    init() {}
    
    func queryInitial(complete: @escaping () -> Void) {
        self.errorText = nil
        ApiService.getMe { res in
            switch res {
            case .success(let output):
                self.errorText = nil
                self.relationships = output.relationships
                self.receivedPartnerRequests = output.receivedPartnerRequests
            case .failure(let err):
                self.errorText = err.localizedDescription
            }
            complete()
        }
    }
    
    func removeReceivedPartnerRequest(_ reqId: UUID) {
        self.receivedPartnerRequests.removeAll { $0.id == reqId }
    }
}
