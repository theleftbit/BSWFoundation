//
//  Error+Extensions.swift
//  Created by Pierluigi Cifani on 11/07/2019.
//

import Foundation

public extension Error {
    var isURLCancelled: Bool {
        if let apiClientError = self as? APIClient.Error, case .requestCanceled = apiClientError {
            return true
        } else {
            let nsError = self as NSError
            return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
        }
    }
}
