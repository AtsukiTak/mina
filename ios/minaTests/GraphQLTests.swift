//
//  GraphQLTests.swift
//  minaTests
//
//  Created by 高橋篤樹 on 2021/01/08.
//  Copyright © 2021 高橋篤樹. All rights reserved.
//

import XCTest
@testable import mina

class GraphQLTests: XCTestCase {
  
  override func setUpWithError() throws {
    //
  }
  
  override func tearDownWithError() throws {
    //
  }
  
  private func assertJson(json: GraphQL.JSON, expected: String) throws {
    let encoder = JSONEncoder()
    let encoded = String(data: try encoder.encode(json), encoding: .utf8)!
    XCTAssertEqual(encoded, expected)
  }
  
  func testJSONEncode() throws {
    try assertJson(json: .string("yey"), expected: "\"yey\"")
    try assertJson(json: .number(42), expected: "42")
    try assertJson(json: .bool(false), expected: "false")
    try assertJson(json: .null, expected: "null")
    try assertJson(json: .array([.string("hoge"), .number(21)]),
                   expected: "[\"hoge\",21]")
    try assertJson(json: .object(["id": .number(42), "name": .string("atsuking")]),
                   expected: "{\"id\":42,\"name\":\"atsuking\"}")
  }
}
