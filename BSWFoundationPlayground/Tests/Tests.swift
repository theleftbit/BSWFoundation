//
//  Tests.swift
//  Tests
//
//  Created by Pierluigi Cifani on 06/08/16.
//
//

import XCTest
@testable import BSWFoundation

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        enum BSWEnvironment: Environment {
            case Production
            
            var basePath: String {
                switch self {
                case .Production:
                    return "https://blurredsoftware.com/"
                }
            }
        }
        
        let drosky = Drosky(environment: BSWEnvironment.Production)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
