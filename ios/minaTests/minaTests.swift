//
//  minaTests.swift
//  minaTests
//
//  Created by 高橋篤樹 on 2020/09/18.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import XCTest
@testable import mina

class minaTests: XCTestCase {
    
    var keychain: KeychainService = KeychainService(serviceName: "me.atsuki.minaTests")

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        // 保存したものを削除する
        try keychain.deleteCred()
    }

    func testKeychain() throws {
        // 最初は何も保存されていない
        XCTAssertEqual(try keychain.readCred(), nil)
        
        // 適切に保存できる
        try keychain.saveCred(cred: Credential(username: "atsuki", password: "hoge"))
        
        // 保存したものを取得できる
        let saved = try keychain.readCred()!
        XCTAssertEqual(saved.username, "atsuki")
        XCTAssertEqual(saved.password, "hoge")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
