//
//  IdentifiableTests.swift
//  BSWFoundation
//
//  Created by Pierluigi Cifani on 09/02/2017.
//
//

import XCTest
@testable import BSWFoundation

class IdentifiableTests: XCTestCase {

    func testAutomaticEquality() {
        
        struct Model: Identifiable {
            let identity: Identity
        }

        let value1 = Model(identity: "0")
        let value2 = Model(identity: "0")
        XCTAssert(value1 == value2)
    }

}
