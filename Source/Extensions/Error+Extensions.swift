//
//  Error+Extensions.swift
//  Created by Pierluigi Cifani on 11/07/2019.
//

import Foundation

public extension Error {
    var isURLCancelled: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
