//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation

let ModuleName = "com.bswfoundation"

func submoduleName(submodule : String) -> String {
    return ModuleName + "." + submodule
}

public typealias VoidHandler = Void -> Void

public func queueForSubmodule(submodule : String, qualityOfService: NSQualityOfService = .Background) -> NSOperationQueue {
    let queue = NSOperationQueue()
    queue.name = submoduleName(submodule)
    queue.qualityOfService = qualityOfService
    return queue
}

public func undefined<T>(hint: String = "", file: StaticString = #file, line: UInt = #line) -> T {
    let message = hint == "" ? "" : ": \(hint)"
    fatalError("undefined \(T.self)\(message)", file:file, line:line)
}
