//
//  Tests.swift
//  Tests
//
//  Created by Pierluigi Cifani on 06/08/16.
//
//

import XCTest
@testable import BSWFoundation

enum BSWEnvironment: Environment {
    case production
    case staging

    var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://theleftbit.com/")!
        case .staging:
            return URL(string: "https://staging.theleftbit.com/")!
        }
    }

    var shouldAllowInsecureConnections: Bool {
        switch self {
        case .production:
            return false
        default:
            return true
        }
    }
}

class EnvironmentTests: XCTestCase {
    
    func testRouteURL() {
        let sut = BSWEnvironment.production
        XCTAssert(sut.routeURL("login") == "https://theleftbit.com/login")
    }

    func testInsecureConnections() {
        let production = BSWEnvironment.production
        let staging = BSWEnvironment.staging
        XCTAssert(production.serverTrustPolicies.count == 0)
        XCTAssert(staging.serverTrustPolicies.count == 1)
    }
}
