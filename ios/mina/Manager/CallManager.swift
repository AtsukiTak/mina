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
    var mediaConnection: SKWMediaConnection?
    
    @Published var localStream: SKWMediaStream?
    @Published var remoteStream: SKWMediaStream?
    @Published var errMsg: String?
    
    // for develop
    @Published var peerId: String?
    
    static let shared: CallManager = CallManager()
    
    private init() {}
    
    /// 通話プロセスを開始する
    func start() {
        let peerResult = SkyWayService.shared.createPeer()
        if case .failure( _) = peerResult {
            return
        }
        self.skywayPeer = try! peerResult.get()
        
        // onOpen
        self.skywayPeer!.on(.PEER_EVENT_OPEN) { [weak self] obj in
            self!.onPeerOpen(peerId: obj as! String)
        }
        
        // onError
        self.skywayPeer!.on(.PEER_EVENT_ERROR) { [weak self] obj in
            self!.onPeerError(err: obj as! SKWPeerError)
        }
    }
    
    /// SkyWay signaling サーバーとの接続が開かれたとき
    /// PEER_EVENT_OPEN
    private func onPeerOpen(peerId: String) {
        self.peerId = peerId
        // localStreamを生成しセットする
        self.localStream = SkyWayService.shared.createLocalStream(peer: self.skywayPeer!)
        
        // 自分のpeerIdをAPIサーバーに通知する
        // その結果をもって、自分がcallerなのかcalleeなのか決定する
        let targetId: String? = nil
        // let targetId: String? = "uYSwcqMDSX4Kq326" // 適宜変える
        if let targetId = targetId {
            self.makeCall(target: targetId)
        } else {
            self.waitCall()
        }
    }
    
    /// SkyWay signaling サーバーとの接続中にErrorが発生した時
    /// PEER_EVENT_ERROR
    private func onPeerError(err: SKWPeerError) {
        NSLog("Error on peer : %@", err)
        self.errMsg = "問題が発生しました"
    }
    
    /// targetに電話をかける
    /// 成功したら、自分の remoteStream に値がセットされる
    private func makeCall(target: PeerID) {
        // 相手PeerとConnectionを開く
        guard let conn = self.skywayPeer!.call(withId: target, stream: self.localStream!) else {
            self.errMsg = "相手との接続に失敗しました"
            return
        }
        self.mediaConnection = conn
        
        self.setupMediaConnectionCallback()
    }
    
    /// 相手からの着信を待つ
    /// 成功したら、自分のremoteStreamに値がセットされる
    private func waitCall() {
        self.skywayPeer!.on(.PEER_EVENT_CALL) { [weak self] obj in
            self!.mediaConnection = (obj as! SKWMediaConnection)
            self!.setupMediaConnectionCallback()
            self!.mediaConnection?.answer(self!.localStream!)
        }
    }
    
    /// MediaConnectionのcallbackを設定する
    /// - MediaStream開始時
    /// - Error時
    private func setupMediaConnectionCallback() {
        // 相手PeerとのConnectionからMediaStreamを取得する
        self.mediaConnection!.on(.MEDIACONNECTION_EVENT_STREAM) { [weak self] obj in
            NSLog("hogehoge")
            self!.remoteStream = (obj as! SKWMediaStream)
        }
        
        // Error時
        self.mediaConnection!.on(.MEDIACONNECTION_EVENT_ERROR) { [weak self] obj in
            self!.onPeerError(err: obj as! SKWPeerError)
        }
    }
}
