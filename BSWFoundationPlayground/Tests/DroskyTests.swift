//
//  Created by Pierluigi Cifani on 09/02/2017.
//
//

import XCTest
import Alamofire
@testable import BSWFoundation

class DroskyTests: XCTestCase {

    var sut: Drosky!

    override func setUp() {
        super.setUp()
        sut = Drosky(environment: BSWEnvironment.Production)
    }
}
