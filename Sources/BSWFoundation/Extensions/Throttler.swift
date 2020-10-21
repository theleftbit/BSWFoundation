//
//  Throttler.swift
//  Created by Pierluigi Cifani on 29/01/2020.
//

import Foundation

public class Throttler {
    
    private let queue: DispatchQueue
    private var job = DispatchWorkItem(block: {})
    private let maxInterval: Double
    
    public init(seconds: Double, queue: DispatchQueue = .global(qos: .default)) {
        self.maxInterval = seconds
        self.queue = queue
    }
    
    public func throttle(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem() { 
            block()
        }
        queue.asyncAfter(deadline: .now() + Double(maxInterval), execute: job)
    }
}
