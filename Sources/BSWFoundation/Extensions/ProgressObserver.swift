//
//  Created by Pierluigi Cifani on 04/07/16.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

/// A simple wrapper on top of `Foundation.Progress` that makes it easier to observe it's progress.
public final class ProgressObserver: NSObject, Sendable {
    
    private let onUpdate: @MainActor (Progress) -> Void
    private let progress: Progress
    private nonisolated(unsafe) var observer: NSKeyValueObservation!
    
    public init(progress: Progress, onUpdate: @escaping @MainActor (Progress) -> Void) {
        self.progress = progress
        self.onUpdate = onUpdate
        super.init()
        self.observer = progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
            guard let onUpdate = self?.onUpdate else { return }
            Task { @MainActor in
                onUpdate(progress)
            }
        }
    }
    
    deinit {
        self.observer.invalidate()
        self.observer = nil
    }
}
