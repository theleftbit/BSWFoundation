//
//  Created by Pierluigi Cifani on 06/08/16.
//
//

import XCTest
@testable import BSWFoundation

class EnvironmentTests: XCTestCase {
    
    func testRouteURL() {
        let sut = BSWEnvironment.production
        XCTAssert(sut.routeURL("login") == "https://theleftbit.com/login")
    }

    func testInsecureConnections() {
        let production = BSWEnvironment.production
        let staging = BSWEnvironment.staging
        XCTAssert(production.shouldAllowInsecureConnections == false)
        XCTAssert(staging.shouldAllowInsecureConnections == true)
    }
}
