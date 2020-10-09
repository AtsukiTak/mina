//
//  SkyWayService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/07.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import Combine
import SkyWay

typealias PeerID = String

enum SkyWayError: Error {
    case failedToCreatePeer
    case failedToMakeCall
}

final class SkyWayService {
    
    let apiKey: String
    let domain: String
    
    static let shared: SkyWayService = SkyWayService(
        apiKey: Secrets.shared.skywayApiKey,
        domain: Secrets.shared.skywayDomain
    )
    
    init(apiKey: String, domain: String) {
        self.apiKey = apiKey
        self.domain = domain
    }
    
    /// SKWPeerを作成する
    func createPeer() -> Result<SKWPeer, Error> {
        let options = SKWPeerOption.init()
        options.key = self.apiKey
        options.domain = self.domain
        options.debug = .DEBUG_LEVEL_ERROR_AND_WARNING
        
        guard let peer = SKWPeer(options: options) else {
            return .failure(SkyWayError.failedToCreatePeer)
        }
        
        return .success(peer)
    }
    
    /// localStreamを生成する
    func createLocalStream(peer: SKWPeer) -> SKWMediaStream? {
        let constrains = SKWMediaConstraints()
        SKWNavigator.initialize(peer)
        return SKWNavigator.getUserMedia(constrains)
    }
}
