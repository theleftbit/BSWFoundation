//
//  Created by Pierluigi Cifani on 06/08/16.
//
//
#if canImport(Testing)
import Testing
@testable import BSWFoundation
import Foundation

actor EnvironmentTests {
    
    @Test
    func routeURL() {
        let sut = BSWEnvironment.production
        #expect(sut.routeURL("login") == "https://theleftbit.com/login")
    }

    @Test
    func insecureConnections() {
        let production = BSWEnvironment.production
        let staging = BSWEnvironment.staging
        #expect(production.shouldAllowInsecureConnections == false)
        #expect(staging.shouldAllowInsecureConnections == true)
    }
}
#endif
