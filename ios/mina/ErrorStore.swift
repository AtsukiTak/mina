//
//  ErrorStore.swift
//  mina
//
//  Created by 高橋篤樹 on 2021/01/14.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import Foundation

// グローバルなエラーを格納するStore
// RootViewのalertに紐づける
class ErrorStore: ObservableObject {
  @Published var err: ErrorRepr?
  
  // alertのトリガーにするためには、それがIdentifiableに準拠している必要がある。
  // 単純なStringはIdentifiableに準拠していないので新しくErrorRepr構造体を作る。
  // ReprはRepresentationの略。
  // また、エラーの文字列が同一でも別のエラーである可能性があるため、idはUUIDにしている
  struct ErrorRepr: Identifiable {
    var id: UUID
    var desc: String
    
    init(_ desc: String) {
      self.id = UUID()
      self.desc = desc
    }
  }
  
  func clear() {
    DispatchQueue.main.async {
      self.err = nil
    }
  }
  
  func set(_ err: Error) {
    self.set(err.localizedDescription)
  }
  
  func set(_ err: String) {
    DispatchQueue.main.async {
      self.err = ErrorRepr(err)
    }
  }
}
