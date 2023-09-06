//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation

let ModuleName = "com.bswfoundation"

nonisolated func submoduleName(_ submodule : String) -> String {
    return ModuleName + "." + submodule
}

public typealias VoidHandler = () -> ()

func queueForSubmodule(_ submodule : String, qualityOfService: QualityOfService = .default) -> OperationQueue {
    let queue = OperationQueue()
    queue.name = submoduleName(submodule)
    queue.qualityOfService = qualityOfService
    return queue
}
