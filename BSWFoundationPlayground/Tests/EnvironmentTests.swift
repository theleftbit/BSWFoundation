//
//  Tests.swift
//  Tests
//
//  Created by Pierluigi Cifani on 06/08/16.
//
//

import XCTest
@testable import BSWFoundation

private enum BSWEnvironment: Environment {
    case Production
    var basePath: String {
        switch self {
        case .Production:
            return "https://blurredsoftware.com/"
        }
    }
}

class EnvironmentTests: XCTestCase {
    
    private let sut = BSWEnvironment.Production
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func testRouteURL() {
        XCTAssert(sut.routeURL("login") == "https://blurredsoftware.com/login")
    }
}
