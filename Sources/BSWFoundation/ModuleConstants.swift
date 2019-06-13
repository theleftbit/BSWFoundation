//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation

let ModuleName = "com.bswfoundation"

func submoduleName(_ submodule : String) -> String {
    return ModuleName + "." + submodule
}

public typealias VoidHandler = () -> ()

func queueForSubmodule(_ submodule : String, qualityOfService: QualityOfService = .default) -> OperationQueue {
    let queue = OperationQueue()
    queue.name = submoduleName(submodule)
    queue.qualityOfService = qualityOfService
    return queue
}

public func undefined<T>(_ hint: String = "", file: StaticString = #file, line: UInt = #line) -> T {
    let message = hint == "" ? "" : ": \(hint)"
    fatalError("undefined \(T.self)\(message)", file:file, line:line)
}

public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
