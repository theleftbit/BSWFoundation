//
//  ModuleConstants.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Foundation

let ModuleName = "com.bswfoundation"

func submoduleName(submodule : String) -> String {
    return ModuleName + "." + submodule
}

func queueForSubmodule(submodule : String) -> dispatch_queue_t {
    return dispatch_queue_create(submoduleName(submodule), nil)
}
