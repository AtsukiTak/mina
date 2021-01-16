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



struct SkyWayService {
  
  let apiKey: String
  let domain: String
  
  enum SkyWayError: Error {
    case failedToCreatePeer
    case failedToMakeCall
    case peerError(SKWPeerError)
  }
  
  init() {
    self.init(apiKey: Secrets.shared.skywayApiKey, domain: Secrets.shared.skywayDomain)
  }
  
  init(apiKey: String, domain: String) {
    self.apiKey = apiKey
    self.domain = domain
  }
  
  /// SKWPeerを作成する
  func createPeer() -> Result<Peer, Error> {
    let options = SKWPeerOption.init()
    options.key = self.apiKey
    options.domain = self.domain
    options.debug = .DEBUG_LEVEL_ERROR_AND_WARNING
    
    guard let peer = SKWPeer(options: options) else {
      return .failure(SkyWayError.failedToCreatePeer)
    }
    
    return .success(Peer(peer: peer))
  }
  
  struct Peer {
    var peer: SKWPeer
    var id: PeerID?
    
    init(peer: SKWPeer) {
      self.peer = peer
      self.id = nil
    }
    
    func createLocalStream() -> SKWMediaStream? {
      let constrains = SKWMediaConstraints()
      SKWNavigator.initialize(self.peer)
      return SKWNavigator.getUserMedia(constrains)
    }
    
    // 相手との間にMediaConnectionを開き、MediaStreamを送る
    func call(target: PeerID, localStream: SKWMediaStream) -> MediaConnection? {
      self.peer
        .call(withId: target, stream: localStream)
        .map({ conn in MediaConnection(conn: conn) })
    }
    
    // シグナリングサーバーとの接続を切る
    func disconnect() {
      self.peer.disconnect()
    }
    
    // シグナリングサーバーとの接続が開いた時
    // 相手Peerとの接続が開いた時ではないことに注意
    func onOpen(handler: @escaping (PeerID) -> Void) {
      self.peer.on(.PEER_EVENT_OPEN, callback: { obj in
        handler(obj as! PeerID)
      })
    }
    
    // シグナリングサーバーとの接続が切れた時
    // 相手Peerとの接続が切れた時ではないことに注意
    func onDisconnected(handler: @escaping () -> Void) {
      self.peer.on(.PEER_EVENT_DISCONNECTED, callback: { obj in
        handler()
      })
    }
    
    // エラーが発生した時
    func onError(handler: @escaping (SkyWayError) -> Void) {
      self.peer.on(.PEER_EVENT_ERROR, callback: { obj in
        handler(.peerError(obj as! SKWPeerError))
      })
    }
    
    // 相手からの着信があったとき
    func onCall(handler: @escaping (MediaConnection) -> Void) {
      self.peer.on(.PEER_EVENT_CALL, callback: { obj in
        let conn = obj as! SKWMediaConnection
        handler(MediaConnection(conn: conn))
      })
    }
    
    // Peerが破棄されたとき
    func onClose(handler: @escaping () -> Void) {
      self.peer.on(.PEER_EVENT_CLOSE, callback: { _ in
        handler()
      })
    }
  }
  
  struct MediaConnection {
    var conn: SKWMediaConnection
    
    // 相手PeerにMediaStreamを送る
    func answer(localStream: SKWMediaStream) {
      self.conn.answer(localStream)
    }
    
    // MediaConnectionのcloseをシグナリングする（この後にonCloseコールバックが呼び出される）
    func close() {
      self.conn.close()
    }
    
    // 相手PeerからMediaStreamが送られてきたとき
    func onReceive(handler: @escaping (SKWMediaStream) -> Void) {
      self.conn.on(.MEDIACONNECTION_EVENT_STREAM, callback: { obj in
        handler(obj as! SKWMediaStream)
      })
    }
    
    // 自分または相手がMediaConnectionを閉じたとき
    func onClose(handler: @escaping () -> Void) {
      self.conn.on(.MEDIACONNECTION_EVENT_CLOSE, callback: { _ in
        handler()
      })
    }
    
    // エラーが発生したとき
    func onError(handler: @escaping (SkyWayError) -> Void) {
      self.conn.on(.MEDIACONNECTION_EVENT_ERROR, callback: { obj in
        handler(.peerError(obj as! SKWPeerError))
      })
    }
  }
}
