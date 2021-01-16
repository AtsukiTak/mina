//
//  CallStore.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/15.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation
import SkyWay

class CallStore: ObservableObject {
  // not nilのとき、通話中
  @Published var peer: SkyWayService.Peer?
  var mediaConn: SkyWayService.MediaConnection?
  @Published var localStream: SKWMediaStream?
  @Published var remoteStream: SKWMediaStream?
  
  var errorStore: ErrorStore
  
  init(errorStore: ErrorStore) {
    self.errorStore = errorStore
  }
  
  func startCallProcess() {
    do {
      let peer = try SkyWayService().createPeer().get()
      self.peer = peer
      
      guard let localStream = peer.createLocalStream() else {
        return self.errorStore.set("unable to access camera or mic")
      }
      self.localStream = localStream
      
      // シグナリングサーバーとの接続が開いた時
      peer.onOpen { [weak self] peerId in
        // サーバーに通知
        // その結果をもって、自分がcallerなのかcalleeなのかを決定する
        let targetId: String? = nil // for develop
        
        if let targetId = targetId {
          self?.makeCall(targetId: targetId)
        } else {
          self?.waitCall()
        }
      }
      
      // シグナリングサーバーとの接続が切れても何もしない
      // （タイミングによっては何かした方がいい？）
      peer.onDisconnected { }
      
      // Peerが破棄されたとき、Storeをクリアする
      peer.onClose {
        DispatchQueue.main.async {
          self.peer = nil
          self.mediaConn = nil
          self.localStream = nil
          self.remoteStream = nil
        }
      }
      
      // エラーを表示する
      peer.onError { [weak self] err in self?.errorStore.set(err) }
    } catch {
      self.errorStore.set(error)
    }
  }
  
  // callを発信する側
  private func makeCall(targetId: String) {
    guard let peer = self.peer, let localStream = self.localStream else {
      return;
    }
    
    guard let mediaConn = peer.call(target: targetId, localStream: localStream) else {
      return self.errorStore.set("相手との接続に失敗しました")
    }
    
    DispatchQueue.main.async {
      self.mediaConn = mediaConn
      self.setupMediaConnectionCallback()
    }
  }
  
  // callを受ける側
  private func waitCall() {
    self.peer?.onCall { [weak self] mediaConn in
      DispatchQueue.main.async {
        // 通話がまだ終了していない場合
        if let self = self, let localStream = self.localStream {
          self.mediaConn = mediaConn
          self.setupMediaConnectionCallback()
          self.mediaConn?.answer(localStream: localStream)
        }
      }
    }
  }
  
  // MediaConnectionが開かれた時、各種callbackを設定する
  private func setupMediaConnectionCallback() {
    guard let mediaConn = self.mediaConn else {
      return
    }
    
    // 相手PeerからMediaStreamが配信開始されたとき
    mediaConn.onReceive { [weak self] remoteStream in
      DispatchQueue.main.async { self?.remoteStream = remoteStream }
    }
    
    // 自分または相手がMediaConnectionを閉じた時
    // 通話状態を終了する
    mediaConn.onClose { [weak self] in
      DispatchQueue.main.async {
        self?.peer?.disconnect()
        self?.peer = nil
        self?.mediaConn = nil
        self?.localStream = nil
        self?.remoteStream = nil
      }
    }
    
    mediaConn.onError { [weak self] err in
      self?.errorStore.set(err)
      // # 要考察
      // errorが起きた後にはcloseが呼び出される？
      // errorが起きても通話が終了しないケースもある？
    }
  }
}
