//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation

nonisolated func submoduleName(_ submodule : String) -> String {
    let ModuleName = "com.bswfoundation"
    return ModuleName + "." + submodule
}

public typealias VoidHandler = () -> ()
