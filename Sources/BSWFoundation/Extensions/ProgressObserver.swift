//
//  Created by Pierluigi Cifani on 04/07/16.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

public class ProgressObserver: NSObject {
    
    fileprivate let onUpdate: (Progress) -> Void
    fileprivate let progress: Progress
    
    private var observer: NSKeyValueObservation!
    
    public init(progress: Progress, onUpdate: @escaping (Progress) -> Void) {
        self.progress = progress
        self.onUpdate = onUpdate
        super.init()
        self.observer = progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.onUpdate(progress)
            }
        }
    }
    
    deinit {
        self.observer.invalidate()
        self.observer = nil
    }
}
