//
//  File.swift
//  BSWFoundation
//
//  Created by Pierluigi Cifani on 21/12/24.
//

import Foundation
import BSWFoundation

#if os(Android)

import XCTest

class UserDefaultsBacked_AndroidTests: XCTestCase {

    func testItStoresStrings() throws {
        class Mock {
            @UserDefaultsBacked(key: "Hello") var someValue: Int?
        }
        
        var sut: Mock? = Mock()
        sut?.someValue = 8
        sut = nil
        sut = Mock()
        let value = try XCTUnwrap(sut?.someValue)
        XCTAssert(value == 8)
    }

}
#endif
