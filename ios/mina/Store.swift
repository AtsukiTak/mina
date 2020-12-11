//
//  Store.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

class Store: ObservableObject {
    @Published var callMode: Bool = false
    @Published var me: Me? = nil
    @Published var relationships: [Relationship] = []
    @Published var receivedPartnerRequests: [PartnerRequest] = []
    @Published var errorText: String? = nil
    
    init() {}
    
    func queryInitial(complete: @escaping () -> Void) {
        self.errorText = nil
        
        do {
            self.me = try KeychainService().readMe()
        } catch {
            self.errorText = error.localizedDescription
            return;
        }
        
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
    
    func acceptPartnerRequest(requestId: UUID, onComplete: (() -> Void)?) {
        if !self.receivedPartnerRequests.contains(where: { $0.id == requestId }) {
            onComplete?()
            return;
        }
        
        self.errorText = nil
        
        ApiService.acceptPartnerRequest(requestId: requestId) { res in
            switch res {
            case .success(_):
                self.receivedPartnerRequests.removeAll(where: { $0.id == requestId})
            case .failure(let err):
                self.errorText = err.localizedDescription
            }
            onComplete?()
        }
    }
}
