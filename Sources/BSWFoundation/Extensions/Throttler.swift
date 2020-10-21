//
//  Throttler.swift
//  Created by Pierluigi Cifani on 29/01/2020.
//

import Foundation

public class Throttler {
    
    public var queue: DispatchQueue = DispatchQueue.global(qos: .default)
    
    private var job = DispatchWorkItem(block: {})
    private var previousRun: Date!
    private let maxInterval: Double
    
    public init(seconds: Double) {
        self.maxInterval = seconds
    }
    
    public func throttle(block: @escaping () -> ()) {
        if previousRun == nil {
            self.previousRun = Date()
        }
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}
