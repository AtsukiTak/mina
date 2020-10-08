//
//  SkyWayService.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/05.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation
import Combine
import SkyWay

/// 通話に関する状態を管理するクラス
final class CallManager: ObservableObject {
    
    var skywayPeer: SKWPeer?
    @Published var localStream: SKWMediaStream?
    @Published var remoteStream: SKWMediaStream?
    var mediaConnection: SKWMediaConnection?
    
    // for develop
    @Published var peerId: String?
    
    static let shared: CallManager = CallManager()
    
    private init() {}
    
    func start() {
        let peerResult = SkyWayService.shared.createPeer()
        if case .failure( _) = peerResult {
            return
        }
        self.skywayPeer = try! peerResult.get()
        
        self.skywayPeer!.on(.PEER_EVENT_OPEN) { [weak self] obj in
            NSLog("my peer is is : %@", (obj as? String) ?? "nil")
            self!.peerId = (obj as! String)
            self!.localStream = SkyWayService.shared.createLocalStream(peer: self!.skywayPeer!)
        }
    }
    
    /// 通話プロセスを開始する
    /// (localStream, remoteStream) な値を1度だけ返すPublisherを返す
    func start2() -> AnyPublisher<(SKWMediaStream, SKWMediaStream), Error> {
        NSLog("started")
        let peerResult = SkyWayService.shared.createPeer()
        if case .failure(let err) = peerResult {
            return Fail(error: err).eraseToAnyPublisher()
        }
        let peer = try! peerResult.get()
        
        self.skywayPeer = peer
        
        let openFuture = Future<String, Error> { promise in
            NSLog("hoge")
            peer.on(.PEER_EVENT_OPEN) { obj in
                NSLog("fuga")
                return promise(.success(obj as! String))
            }
        }
        
        return openFuture
            .flatMap { [weak self] _ in
                self!.registerMyPeerId()
            }
            .flatMap { [weak self] target -> AnyPublisher<SKWMediaStream, Error> in
                self?.localStream = SkyWayService.shared.createLocalStream(peer: peer)
                if let target = target {
                    return self!.makeCall(target: target)
                } else {
                    return self!.waitCall()
                }
            }
            .map { [weak self] remoteStream -> (SKWMediaStream, SKWMediaStream) in
                self!.remoteStream = remoteStream
                return (self!.localStream!, self!.remoteStream!)
            }
            .eraseToAnyPublisher()
    }
    
    /// 自分のPeerIDをAPIサーバーに通知する
    private func registerMyPeerId() -> AnyPublisher<String?, Error> {
        let peerId = self.skywayPeer!.identity!
        self.peerId = peerId
        NSLog("my peer id is : %@", peerId)
        return AppDelegate.shared
            .apiService
            .registerPeerId(peerId: peerId)
            .map { res in res.targetPeerId }
            .eraseToAnyPublisher()
    }
    
    /// 相手に電話をかける
    private func makeCall(target: PeerID) -> AnyPublisher<SKWMediaStream, Error> {
        return SkyWayService.shared.openP2PConnection(peer: self.skywayPeer!, target: target, localStream: self.localStream!)
            .publisher
            .flatMap { [weak self] conn -> Future<SKWMediaStream, Error> in
                self!.mediaConnection = conn
                return SkyWayService.shared.createRemoteStream(conn: conn)
            }
            .eraseToAnyPublisher()
    }
    
    /// 相手からの着信を待つ
    private func waitCall() -> AnyPublisher<SKWMediaStream, Error> {
        return SkyWayService.shared.receiveP2PConnection(peer: self.skywayPeer!)
            .flatMap { [weak self] conn -> Future<SKWMediaStream, Error> in
                self!.mediaConnection = conn
                return SkyWayService.shared.createRemoteStream(conn: conn)
            }
            .eraseToAnyPublisher()
    }
}

protocol MediaStreamDelegate {
    func onOpen(localStream: SKWMediaStream, remoteStream: SKWMediaStream)
    
    func onError()
}
