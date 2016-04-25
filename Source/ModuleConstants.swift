//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation

let ModuleName = "com.bswfoundation"

func submoduleName(submodule : String) -> String {
    return ModuleName + "." + submodule
}

public func queueForSubmodule(submodule : String) -> dispatch_queue_t {
    return dispatch_queue_create(submoduleName(submodule), nil)
}

public func undefined<T>(hint: String = "", file: StaticString = #file, line: UInt = #line) -> T {
    let message = hint == "" ? "" : ": \(hint)"
    fatalError("undefined \(T.self)\(message)", file:file, line:line)
}
