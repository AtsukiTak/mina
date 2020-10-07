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
    
    /// 相手Peerとの接続を開く
    func openP2PConnection(
        peer: SKWPeer,
        target: PeerID,
        localStream: SKWMediaStream,
        options: SKWCallOption = SKWCallOption()
    ) -> Result<SKWMediaConnection, Error> {
        let res = peer.call(withId: target, stream: localStream, options: options)
        guard let mediaConnection = res else {
            return .failure(SkyWayError.failedToMakeCall)
        }
        return .success(mediaConnection)
    }
    
    /// 相手Peerが接続を開くのを待つ
    func receiveP2PConnection(peer: SKWPeer) -> Future<SKWMediaConnection, Error> {
        Future { promise in
            peer.on(.PEER_EVENT_CALL) { obj in
                promise(.success(obj as! SKWMediaConnection))
            }
        }
    }
    
    /// remoteStreamを生成する
    func createRemoteStream(conn: SKWMediaConnection) -> Future<SKWMediaStream, Error> {
        Future { promise in
            conn.on(.MEDIACONNECTION_EVENT_STREAM) { obj in
                promise(.success(obj as! SKWMediaStream))
            }
        }
    }
}
