//
//  RelationshipTest.swift
//  minaTests
//
//  Created by 高橋篤樹 on 2020/11/27.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import XCTest
@testable import mina

class RelationshipTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // `Time` をパースするテスト
    func testParseTime() throws {
        XCTAssertEqual(try! ApiService.parseTime("02:42"), Time(hour: 2, min: 42))
        XCTAssertThrowsError(try ApiService.parseTime("24:21"))
        XCTAssertThrowsError(try ApiService.parseTime("24-21"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
